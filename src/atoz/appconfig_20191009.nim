
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

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
  Scheme {.pure.} = enum
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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "appconfig.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appconfig.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appconfig.us-west-2.amazonaws.com",
                           "eu-west-2": "appconfig.eu-west-2.amazonaws.com", "ap-northeast-3": "appconfig.ap-northeast-3.amazonaws.com", "eu-central-1": "appconfig.eu-central-1.amazonaws.com",
                           "us-east-2": "appconfig.us-east-2.amazonaws.com",
                           "us-east-1": "appconfig.us-east-1.amazonaws.com", "cn-northwest-1": "appconfig.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "appconfig.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "appconfig.ap-south-1.amazonaws.com",
                           "eu-north-1": "appconfig.eu-north-1.amazonaws.com",
                           "us-west-1": "appconfig.us-west-1.amazonaws.com", "us-gov-east-1": "appconfig.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "appconfig.eu-west-3.amazonaws.com", "cn-north-1": "appconfig.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "appconfig.sa-east-1.amazonaws.com",
                           "eu-west-1": "appconfig.eu-west-1.amazonaws.com", "us-gov-west-1": "appconfig.us-gov-west-1.amazonaws.com", "ap-southeast-2": "appconfig.ap-southeast-2.amazonaws.com", "ca-central-1": "appconfig.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "appconfig.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "appconfig.ap-southeast-1.amazonaws.com",
      "us-west-2": "appconfig.us-west-2.amazonaws.com",
      "eu-west-2": "appconfig.eu-west-2.amazonaws.com",
      "ap-northeast-3": "appconfig.ap-northeast-3.amazonaws.com",
      "eu-central-1": "appconfig.eu-central-1.amazonaws.com",
      "us-east-2": "appconfig.us-east-2.amazonaws.com",
      "us-east-1": "appconfig.us-east-1.amazonaws.com",
      "cn-northwest-1": "appconfig.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "appconfig.ap-northeast-2.amazonaws.com",
      "ap-south-1": "appconfig.ap-south-1.amazonaws.com",
      "eu-north-1": "appconfig.eu-north-1.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateApplication_617467 = ref object of OpenApiRestCall_616866
proc url_CreateApplication_617469(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_617468(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
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
  var valid_617470 = header.getOrDefault("X-Amz-Date")
  valid_617470 = validateParameter(valid_617470, JString, required = false,
                                 default = nil)
  if valid_617470 != nil:
    section.add "X-Amz-Date", valid_617470
  var valid_617471 = header.getOrDefault("X-Amz-Security-Token")
  valid_617471 = validateParameter(valid_617471, JString, required = false,
                                 default = nil)
  if valid_617471 != nil:
    section.add "X-Amz-Security-Token", valid_617471
  var valid_617472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617472 = validateParameter(valid_617472, JString, required = false,
                                 default = nil)
  if valid_617472 != nil:
    section.add "X-Amz-Content-Sha256", valid_617472
  var valid_617473 = header.getOrDefault("X-Amz-Algorithm")
  valid_617473 = validateParameter(valid_617473, JString, required = false,
                                 default = nil)
  if valid_617473 != nil:
    section.add "X-Amz-Algorithm", valid_617473
  var valid_617474 = header.getOrDefault("X-Amz-Signature")
  valid_617474 = validateParameter(valid_617474, JString, required = false,
                                 default = nil)
  if valid_617474 != nil:
    section.add "X-Amz-Signature", valid_617474
  var valid_617475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617475 = validateParameter(valid_617475, JString, required = false,
                                 default = nil)
  if valid_617475 != nil:
    section.add "X-Amz-SignedHeaders", valid_617475
  var valid_617476 = header.getOrDefault("X-Amz-Credential")
  valid_617476 = validateParameter(valid_617476, JString, required = false,
                                 default = nil)
  if valid_617476 != nil:
    section.add "X-Amz-Credential", valid_617476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617478: Call_CreateApplication_617467; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ## 
  let valid = call_617478.validator(path, query, header, formData, body, _)
  let scheme = call_617478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617478.url(scheme.get, call_617478.host, call_617478.base,
                         call_617478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617478, url, valid, _)

proc call*(call_617479: Call_CreateApplication_617467; body: JsonNode): Recallable =
  ## createApplication
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ##   body: JObject (required)
  var body_617480 = newJObject()
  if body != nil:
    body_617480 = body
  result = call_617479.call(nil, nil, nil, nil, body_617480)

var createApplication* = Call_CreateApplication_617467(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_617468, base: "/",
    url: url_CreateApplication_617469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_617205 = ref object of OpenApiRestCall_616866
proc url_ListApplications_617207(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_617206(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## List all applications in your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617319 = query.getOrDefault("next_token")
  valid_617319 = validateParameter(valid_617319, JString, required = false,
                                 default = nil)
  if valid_617319 != nil:
    section.add "next_token", valid_617319
  var valid_617320 = query.getOrDefault("max_results")
  valid_617320 = validateParameter(valid_617320, JInt, required = false, default = nil)
  if valid_617320 != nil:
    section.add "max_results", valid_617320
  var valid_617321 = query.getOrDefault("NextToken")
  valid_617321 = validateParameter(valid_617321, JString, required = false,
                                 default = nil)
  if valid_617321 != nil:
    section.add "NextToken", valid_617321
  var valid_617322 = query.getOrDefault("MaxResults")
  valid_617322 = validateParameter(valid_617322, JString, required = false,
                                 default = nil)
  if valid_617322 != nil:
    section.add "MaxResults", valid_617322
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
  var valid_617323 = header.getOrDefault("X-Amz-Date")
  valid_617323 = validateParameter(valid_617323, JString, required = false,
                                 default = nil)
  if valid_617323 != nil:
    section.add "X-Amz-Date", valid_617323
  var valid_617324 = header.getOrDefault("X-Amz-Security-Token")
  valid_617324 = validateParameter(valid_617324, JString, required = false,
                                 default = nil)
  if valid_617324 != nil:
    section.add "X-Amz-Security-Token", valid_617324
  var valid_617325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617325 = validateParameter(valid_617325, JString, required = false,
                                 default = nil)
  if valid_617325 != nil:
    section.add "X-Amz-Content-Sha256", valid_617325
  var valid_617326 = header.getOrDefault("X-Amz-Algorithm")
  valid_617326 = validateParameter(valid_617326, JString, required = false,
                                 default = nil)
  if valid_617326 != nil:
    section.add "X-Amz-Algorithm", valid_617326
  var valid_617327 = header.getOrDefault("X-Amz-Signature")
  valid_617327 = validateParameter(valid_617327, JString, required = false,
                                 default = nil)
  if valid_617327 != nil:
    section.add "X-Amz-Signature", valid_617327
  var valid_617328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617328 = validateParameter(valid_617328, JString, required = false,
                                 default = nil)
  if valid_617328 != nil:
    section.add "X-Amz-SignedHeaders", valid_617328
  var valid_617329 = header.getOrDefault("X-Amz-Credential")
  valid_617329 = validateParameter(valid_617329, JString, required = false,
                                 default = nil)
  if valid_617329 != nil:
    section.add "X-Amz-Credential", valid_617329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617353: Call_ListApplications_617205; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List all applications in your AWS account.
  ## 
  let valid = call_617353.validator(path, query, header, formData, body, _)
  let scheme = call_617353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617353.url(scheme.get, call_617353.host, call_617353.base,
                         call_617353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617353, url, valid, _)

proc call*(call_617424: Call_ListApplications_617205; nextToken: string = "";
          maxResults: int = 0; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listApplications
  ## List all applications in your AWS account.
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617425 = newJObject()
  add(query_617425, "next_token", newJString(nextToken))
  add(query_617425, "max_results", newJInt(maxResults))
  add(query_617425, "NextToken", newJString(NextToken))
  add(query_617425, "MaxResults", newJString(MaxResults))
  result = call_617424.call(nil, query_617425, nil, nil, nil)

var listApplications* = Call_ListApplications_617205(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_617206, base: "/",
    url: url_ListApplications_617207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationProfile_617514 = ref object of OpenApiRestCall_616866
proc url_CreateConfigurationProfile_617516(protocol: Scheme; host: string;
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

proc validate_CreateConfigurationProfile_617515(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617517 = path.getOrDefault("ApplicationId")
  valid_617517 = validateParameter(valid_617517, JString, required = true,
                                 default = nil)
  if valid_617517 != nil:
    section.add "ApplicationId", valid_617517
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
  var valid_617518 = header.getOrDefault("X-Amz-Date")
  valid_617518 = validateParameter(valid_617518, JString, required = false,
                                 default = nil)
  if valid_617518 != nil:
    section.add "X-Amz-Date", valid_617518
  var valid_617519 = header.getOrDefault("X-Amz-Security-Token")
  valid_617519 = validateParameter(valid_617519, JString, required = false,
                                 default = nil)
  if valid_617519 != nil:
    section.add "X-Amz-Security-Token", valid_617519
  var valid_617520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617520 = validateParameter(valid_617520, JString, required = false,
                                 default = nil)
  if valid_617520 != nil:
    section.add "X-Amz-Content-Sha256", valid_617520
  var valid_617521 = header.getOrDefault("X-Amz-Algorithm")
  valid_617521 = validateParameter(valid_617521, JString, required = false,
                                 default = nil)
  if valid_617521 != nil:
    section.add "X-Amz-Algorithm", valid_617521
  var valid_617522 = header.getOrDefault("X-Amz-Signature")
  valid_617522 = validateParameter(valid_617522, JString, required = false,
                                 default = nil)
  if valid_617522 != nil:
    section.add "X-Amz-Signature", valid_617522
  var valid_617523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617523 = validateParameter(valid_617523, JString, required = false,
                                 default = nil)
  if valid_617523 != nil:
    section.add "X-Amz-SignedHeaders", valid_617523
  var valid_617524 = header.getOrDefault("X-Amz-Credential")
  valid_617524 = validateParameter(valid_617524, JString, required = false,
                                 default = nil)
  if valid_617524 != nil:
    section.add "X-Amz-Credential", valid_617524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617526: Call_CreateConfigurationProfile_617514;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ## 
  let valid = call_617526.validator(path, query, header, formData, body, _)
  let scheme = call_617526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617526.url(scheme.get, call_617526.host, call_617526.base,
                         call_617526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617526, url, valid, _)

proc call*(call_617527: Call_CreateConfigurationProfile_617514;
          ApplicationId: string; body: JsonNode): Recallable =
  ## createConfigurationProfile
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_617528 = newJObject()
  var body_617529 = newJObject()
  add(path_617528, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_617529 = body
  result = call_617527.call(path_617528, nil, nil, nil, body_617529)

var createConfigurationProfile* = Call_CreateConfigurationProfile_617514(
    name: "createConfigurationProfile", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_CreateConfigurationProfile_617515, base: "/",
    url: url_CreateConfigurationProfile_617516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationProfiles_617481 = ref object of OpenApiRestCall_616866
proc url_ListConfigurationProfiles_617483(protocol: Scheme; host: string;
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

proc validate_ListConfigurationProfiles_617482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617498 = path.getOrDefault("ApplicationId")
  valid_617498 = validateParameter(valid_617498, JString, required = true,
                                 default = nil)
  if valid_617498 != nil:
    section.add "ApplicationId", valid_617498
  result.add "path", section
  ## parameters in `query` object:
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617499 = query.getOrDefault("next_token")
  valid_617499 = validateParameter(valid_617499, JString, required = false,
                                 default = nil)
  if valid_617499 != nil:
    section.add "next_token", valid_617499
  var valid_617500 = query.getOrDefault("max_results")
  valid_617500 = validateParameter(valid_617500, JInt, required = false, default = nil)
  if valid_617500 != nil:
    section.add "max_results", valid_617500
  var valid_617501 = query.getOrDefault("NextToken")
  valid_617501 = validateParameter(valid_617501, JString, required = false,
                                 default = nil)
  if valid_617501 != nil:
    section.add "NextToken", valid_617501
  var valid_617502 = query.getOrDefault("MaxResults")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "MaxResults", valid_617502
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
  var valid_617503 = header.getOrDefault("X-Amz-Date")
  valid_617503 = validateParameter(valid_617503, JString, required = false,
                                 default = nil)
  if valid_617503 != nil:
    section.add "X-Amz-Date", valid_617503
  var valid_617504 = header.getOrDefault("X-Amz-Security-Token")
  valid_617504 = validateParameter(valid_617504, JString, required = false,
                                 default = nil)
  if valid_617504 != nil:
    section.add "X-Amz-Security-Token", valid_617504
  var valid_617505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617505 = validateParameter(valid_617505, JString, required = false,
                                 default = nil)
  if valid_617505 != nil:
    section.add "X-Amz-Content-Sha256", valid_617505
  var valid_617506 = header.getOrDefault("X-Amz-Algorithm")
  valid_617506 = validateParameter(valid_617506, JString, required = false,
                                 default = nil)
  if valid_617506 != nil:
    section.add "X-Amz-Algorithm", valid_617506
  var valid_617507 = header.getOrDefault("X-Amz-Signature")
  valid_617507 = validateParameter(valid_617507, JString, required = false,
                                 default = nil)
  if valid_617507 != nil:
    section.add "X-Amz-Signature", valid_617507
  var valid_617508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617508 = validateParameter(valid_617508, JString, required = false,
                                 default = nil)
  if valid_617508 != nil:
    section.add "X-Amz-SignedHeaders", valid_617508
  var valid_617509 = header.getOrDefault("X-Amz-Credential")
  valid_617509 = validateParameter(valid_617509, JString, required = false,
                                 default = nil)
  if valid_617509 != nil:
    section.add "X-Amz-Credential", valid_617509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617510: Call_ListConfigurationProfiles_617481;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the configuration profiles for an application.
  ## 
  let valid = call_617510.validator(path, query, header, formData, body, _)
  let scheme = call_617510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617510.url(scheme.get, call_617510.host, call_617510.base,
                         call_617510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617510, url, valid, _)

proc call*(call_617511: Call_ListConfigurationProfiles_617481;
          ApplicationId: string; nextToken: string = ""; maxResults: int = 0;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listConfigurationProfiles
  ## Lists the configuration profiles for an application.
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var path_617512 = newJObject()
  var query_617513 = newJObject()
  add(query_617513, "next_token", newJString(nextToken))
  add(path_617512, "ApplicationId", newJString(ApplicationId))
  add(query_617513, "max_results", newJInt(maxResults))
  add(query_617513, "NextToken", newJString(NextToken))
  add(query_617513, "MaxResults", newJString(MaxResults))
  result = call_617511.call(path_617512, query_617513, nil, nil, nil)

var listConfigurationProfiles* = Call_ListConfigurationProfiles_617481(
    name: "listConfigurationProfiles", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_ListConfigurationProfiles_617482, base: "/",
    url: url_ListConfigurationProfiles_617483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentStrategy_617547 = ref object of OpenApiRestCall_616866
proc url_CreateDeploymentStrategy_617549(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentStrategy_617548(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
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
  var valid_617550 = header.getOrDefault("X-Amz-Date")
  valid_617550 = validateParameter(valid_617550, JString, required = false,
                                 default = nil)
  if valid_617550 != nil:
    section.add "X-Amz-Date", valid_617550
  var valid_617551 = header.getOrDefault("X-Amz-Security-Token")
  valid_617551 = validateParameter(valid_617551, JString, required = false,
                                 default = nil)
  if valid_617551 != nil:
    section.add "X-Amz-Security-Token", valid_617551
  var valid_617552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617552 = validateParameter(valid_617552, JString, required = false,
                                 default = nil)
  if valid_617552 != nil:
    section.add "X-Amz-Content-Sha256", valid_617552
  var valid_617553 = header.getOrDefault("X-Amz-Algorithm")
  valid_617553 = validateParameter(valid_617553, JString, required = false,
                                 default = nil)
  if valid_617553 != nil:
    section.add "X-Amz-Algorithm", valid_617553
  var valid_617554 = header.getOrDefault("X-Amz-Signature")
  valid_617554 = validateParameter(valid_617554, JString, required = false,
                                 default = nil)
  if valid_617554 != nil:
    section.add "X-Amz-Signature", valid_617554
  var valid_617555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617555 = validateParameter(valid_617555, JString, required = false,
                                 default = nil)
  if valid_617555 != nil:
    section.add "X-Amz-SignedHeaders", valid_617555
  var valid_617556 = header.getOrDefault("X-Amz-Credential")
  valid_617556 = validateParameter(valid_617556, JString, required = false,
                                 default = nil)
  if valid_617556 != nil:
    section.add "X-Amz-Credential", valid_617556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617558: Call_CreateDeploymentStrategy_617547; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_617558.validator(path, query, header, formData, body, _)
  let scheme = call_617558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617558.url(scheme.get, call_617558.host, call_617558.base,
                         call_617558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617558, url, valid, _)

proc call*(call_617559: Call_CreateDeploymentStrategy_617547; body: JsonNode): Recallable =
  ## createDeploymentStrategy
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   body: JObject (required)
  var body_617560 = newJObject()
  if body != nil:
    body_617560 = body
  result = call_617559.call(nil, nil, nil, nil, body_617560)

var createDeploymentStrategy* = Call_CreateDeploymentStrategy_617547(
    name: "createDeploymentStrategy", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_CreateDeploymentStrategy_617548, base: "/",
    url: url_CreateDeploymentStrategy_617549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentStrategies_617530 = ref object of OpenApiRestCall_616866
proc url_ListDeploymentStrategies_617532(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentStrategies_617531(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## List deployment strategies.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617533 = query.getOrDefault("next_token")
  valid_617533 = validateParameter(valid_617533, JString, required = false,
                                 default = nil)
  if valid_617533 != nil:
    section.add "next_token", valid_617533
  var valid_617534 = query.getOrDefault("max_results")
  valid_617534 = validateParameter(valid_617534, JInt, required = false, default = nil)
  if valid_617534 != nil:
    section.add "max_results", valid_617534
  var valid_617535 = query.getOrDefault("NextToken")
  valid_617535 = validateParameter(valid_617535, JString, required = false,
                                 default = nil)
  if valid_617535 != nil:
    section.add "NextToken", valid_617535
  var valid_617536 = query.getOrDefault("MaxResults")
  valid_617536 = validateParameter(valid_617536, JString, required = false,
                                 default = nil)
  if valid_617536 != nil:
    section.add "MaxResults", valid_617536
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
  var valid_617537 = header.getOrDefault("X-Amz-Date")
  valid_617537 = validateParameter(valid_617537, JString, required = false,
                                 default = nil)
  if valid_617537 != nil:
    section.add "X-Amz-Date", valid_617537
  var valid_617538 = header.getOrDefault("X-Amz-Security-Token")
  valid_617538 = validateParameter(valid_617538, JString, required = false,
                                 default = nil)
  if valid_617538 != nil:
    section.add "X-Amz-Security-Token", valid_617538
  var valid_617539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617539 = validateParameter(valid_617539, JString, required = false,
                                 default = nil)
  if valid_617539 != nil:
    section.add "X-Amz-Content-Sha256", valid_617539
  var valid_617540 = header.getOrDefault("X-Amz-Algorithm")
  valid_617540 = validateParameter(valid_617540, JString, required = false,
                                 default = nil)
  if valid_617540 != nil:
    section.add "X-Amz-Algorithm", valid_617540
  var valid_617541 = header.getOrDefault("X-Amz-Signature")
  valid_617541 = validateParameter(valid_617541, JString, required = false,
                                 default = nil)
  if valid_617541 != nil:
    section.add "X-Amz-Signature", valid_617541
  var valid_617542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617542 = validateParameter(valid_617542, JString, required = false,
                                 default = nil)
  if valid_617542 != nil:
    section.add "X-Amz-SignedHeaders", valid_617542
  var valid_617543 = header.getOrDefault("X-Amz-Credential")
  valid_617543 = validateParameter(valid_617543, JString, required = false,
                                 default = nil)
  if valid_617543 != nil:
    section.add "X-Amz-Credential", valid_617543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617544: Call_ListDeploymentStrategies_617530; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List deployment strategies.
  ## 
  let valid = call_617544.validator(path, query, header, formData, body, _)
  let scheme = call_617544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617544.url(scheme.get, call_617544.host, call_617544.base,
                         call_617544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617544, url, valid, _)

proc call*(call_617545: Call_ListDeploymentStrategies_617530;
          nextToken: string = ""; maxResults: int = 0; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDeploymentStrategies
  ## List deployment strategies.
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var query_617546 = newJObject()
  add(query_617546, "next_token", newJString(nextToken))
  add(query_617546, "max_results", newJInt(maxResults))
  add(query_617546, "NextToken", newJString(NextToken))
  add(query_617546, "MaxResults", newJString(MaxResults))
  result = call_617545.call(nil, query_617546, nil, nil, nil)

var listDeploymentStrategies* = Call_ListDeploymentStrategies_617530(
    name: "listDeploymentStrategies", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_ListDeploymentStrategies_617531, base: "/",
    url: url_ListDeploymentStrategies_617532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironment_617580 = ref object of OpenApiRestCall_616866
proc url_CreateEnvironment_617582(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_CreateEnvironment_617581(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617583 = path.getOrDefault("ApplicationId")
  valid_617583 = validateParameter(valid_617583, JString, required = true,
                                 default = nil)
  if valid_617583 != nil:
    section.add "ApplicationId", valid_617583
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
  var valid_617584 = header.getOrDefault("X-Amz-Date")
  valid_617584 = validateParameter(valid_617584, JString, required = false,
                                 default = nil)
  if valid_617584 != nil:
    section.add "X-Amz-Date", valid_617584
  var valid_617585 = header.getOrDefault("X-Amz-Security-Token")
  valid_617585 = validateParameter(valid_617585, JString, required = false,
                                 default = nil)
  if valid_617585 != nil:
    section.add "X-Amz-Security-Token", valid_617585
  var valid_617586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617586 = validateParameter(valid_617586, JString, required = false,
                                 default = nil)
  if valid_617586 != nil:
    section.add "X-Amz-Content-Sha256", valid_617586
  var valid_617587 = header.getOrDefault("X-Amz-Algorithm")
  valid_617587 = validateParameter(valid_617587, JString, required = false,
                                 default = nil)
  if valid_617587 != nil:
    section.add "X-Amz-Algorithm", valid_617587
  var valid_617588 = header.getOrDefault("X-Amz-Signature")
  valid_617588 = validateParameter(valid_617588, JString, required = false,
                                 default = nil)
  if valid_617588 != nil:
    section.add "X-Amz-Signature", valid_617588
  var valid_617589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617589 = validateParameter(valid_617589, JString, required = false,
                                 default = nil)
  if valid_617589 != nil:
    section.add "X-Amz-SignedHeaders", valid_617589
  var valid_617590 = header.getOrDefault("X-Amz-Credential")
  valid_617590 = validateParameter(valid_617590, JString, required = false,
                                 default = nil)
  if valid_617590 != nil:
    section.add "X-Amz-Credential", valid_617590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617592: Call_CreateEnvironment_617580; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ## 
  let valid = call_617592.validator(path, query, header, formData, body, _)
  let scheme = call_617592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617592.url(scheme.get, call_617592.host, call_617592.base,
                         call_617592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617592, url, valid, _)

proc call*(call_617593: Call_CreateEnvironment_617580; ApplicationId: string;
          body: JsonNode): Recallable =
  ## createEnvironment
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_617594 = newJObject()
  var body_617595 = newJObject()
  add(path_617594, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_617595 = body
  result = call_617593.call(path_617594, nil, nil, nil, body_617595)

var createEnvironment* = Call_CreateEnvironment_617580(name: "createEnvironment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_CreateEnvironment_617581, base: "/",
    url: url_CreateEnvironment_617582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_617561 = ref object of OpenApiRestCall_616866
proc url_ListEnvironments_617563(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListEnvironments_617562(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617564 = path.getOrDefault("ApplicationId")
  valid_617564 = validateParameter(valid_617564, JString, required = true,
                                 default = nil)
  if valid_617564 != nil:
    section.add "ApplicationId", valid_617564
  result.add "path", section
  ## parameters in `query` object:
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617565 = query.getOrDefault("next_token")
  valid_617565 = validateParameter(valid_617565, JString, required = false,
                                 default = nil)
  if valid_617565 != nil:
    section.add "next_token", valid_617565
  var valid_617566 = query.getOrDefault("max_results")
  valid_617566 = validateParameter(valid_617566, JInt, required = false, default = nil)
  if valid_617566 != nil:
    section.add "max_results", valid_617566
  var valid_617567 = query.getOrDefault("NextToken")
  valid_617567 = validateParameter(valid_617567, JString, required = false,
                                 default = nil)
  if valid_617567 != nil:
    section.add "NextToken", valid_617567
  var valid_617568 = query.getOrDefault("MaxResults")
  valid_617568 = validateParameter(valid_617568, JString, required = false,
                                 default = nil)
  if valid_617568 != nil:
    section.add "MaxResults", valid_617568
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
  var valid_617569 = header.getOrDefault("X-Amz-Date")
  valid_617569 = validateParameter(valid_617569, JString, required = false,
                                 default = nil)
  if valid_617569 != nil:
    section.add "X-Amz-Date", valid_617569
  var valid_617570 = header.getOrDefault("X-Amz-Security-Token")
  valid_617570 = validateParameter(valid_617570, JString, required = false,
                                 default = nil)
  if valid_617570 != nil:
    section.add "X-Amz-Security-Token", valid_617570
  var valid_617571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617571 = validateParameter(valid_617571, JString, required = false,
                                 default = nil)
  if valid_617571 != nil:
    section.add "X-Amz-Content-Sha256", valid_617571
  var valid_617572 = header.getOrDefault("X-Amz-Algorithm")
  valid_617572 = validateParameter(valid_617572, JString, required = false,
                                 default = nil)
  if valid_617572 != nil:
    section.add "X-Amz-Algorithm", valid_617572
  var valid_617573 = header.getOrDefault("X-Amz-Signature")
  valid_617573 = validateParameter(valid_617573, JString, required = false,
                                 default = nil)
  if valid_617573 != nil:
    section.add "X-Amz-Signature", valid_617573
  var valid_617574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617574 = validateParameter(valid_617574, JString, required = false,
                                 default = nil)
  if valid_617574 != nil:
    section.add "X-Amz-SignedHeaders", valid_617574
  var valid_617575 = header.getOrDefault("X-Amz-Credential")
  valid_617575 = validateParameter(valid_617575, JString, required = false,
                                 default = nil)
  if valid_617575 != nil:
    section.add "X-Amz-Credential", valid_617575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617576: Call_ListEnvironments_617561; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the environments for an application.
  ## 
  let valid = call_617576.validator(path, query, header, formData, body, _)
  let scheme = call_617576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617576.url(scheme.get, call_617576.host, call_617576.base,
                         call_617576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617576, url, valid, _)

proc call*(call_617577: Call_ListEnvironments_617561; ApplicationId: string;
          nextToken: string = ""; maxResults: int = 0; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listEnvironments
  ## List the environments for an application.
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  var path_617578 = newJObject()
  var query_617579 = newJObject()
  add(query_617579, "next_token", newJString(nextToken))
  add(path_617578, "ApplicationId", newJString(ApplicationId))
  add(query_617579, "max_results", newJInt(maxResults))
  add(query_617579, "NextToken", newJString(NextToken))
  add(query_617579, "MaxResults", newJString(MaxResults))
  result = call_617577.call(path_617578, query_617579, nil, nil, nil)

var listEnvironments* = Call_ListEnvironments_617561(name: "listEnvironments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_ListEnvironments_617562, base: "/",
    url: url_ListEnvironments_617563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_617596 = ref object of OpenApiRestCall_616866
proc url_GetApplication_617598(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplication_617597(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617599 = path.getOrDefault("ApplicationId")
  valid_617599 = validateParameter(valid_617599, JString, required = true,
                                 default = nil)
  if valid_617599 != nil:
    section.add "ApplicationId", valid_617599
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
  var valid_617600 = header.getOrDefault("X-Amz-Date")
  valid_617600 = validateParameter(valid_617600, JString, required = false,
                                 default = nil)
  if valid_617600 != nil:
    section.add "X-Amz-Date", valid_617600
  var valid_617601 = header.getOrDefault("X-Amz-Security-Token")
  valid_617601 = validateParameter(valid_617601, JString, required = false,
                                 default = nil)
  if valid_617601 != nil:
    section.add "X-Amz-Security-Token", valid_617601
  var valid_617602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617602 = validateParameter(valid_617602, JString, required = false,
                                 default = nil)
  if valid_617602 != nil:
    section.add "X-Amz-Content-Sha256", valid_617602
  var valid_617603 = header.getOrDefault("X-Amz-Algorithm")
  valid_617603 = validateParameter(valid_617603, JString, required = false,
                                 default = nil)
  if valid_617603 != nil:
    section.add "X-Amz-Algorithm", valid_617603
  var valid_617604 = header.getOrDefault("X-Amz-Signature")
  valid_617604 = validateParameter(valid_617604, JString, required = false,
                                 default = nil)
  if valid_617604 != nil:
    section.add "X-Amz-Signature", valid_617604
  var valid_617605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617605 = validateParameter(valid_617605, JString, required = false,
                                 default = nil)
  if valid_617605 != nil:
    section.add "X-Amz-SignedHeaders", valid_617605
  var valid_617606 = header.getOrDefault("X-Amz-Credential")
  valid_617606 = validateParameter(valid_617606, JString, required = false,
                                 default = nil)
  if valid_617606 != nil:
    section.add "X-Amz-Credential", valid_617606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617607: Call_GetApplication_617596; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_617607.validator(path, query, header, formData, body, _)
  let scheme = call_617607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617607.url(scheme.get, call_617607.host, call_617607.base,
                         call_617607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617607, url, valid, _)

proc call*(call_617608: Call_GetApplication_617596; ApplicationId: string): Recallable =
  ## getApplication
  ## Retrieve information about an application.
  ##   ApplicationId: string (required)
  ##                : The ID of the application you want to get.
  var path_617609 = newJObject()
  add(path_617609, "ApplicationId", newJString(ApplicationId))
  result = call_617608.call(path_617609, nil, nil, nil, nil)

var getApplication* = Call_GetApplication_617596(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_GetApplication_617597,
    base: "/", url: url_GetApplication_617598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_617624 = ref object of OpenApiRestCall_616866
proc url_UpdateApplication_617626(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApplication_617625(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617627 = path.getOrDefault("ApplicationId")
  valid_617627 = validateParameter(valid_617627, JString, required = true,
                                 default = nil)
  if valid_617627 != nil:
    section.add "ApplicationId", valid_617627
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
  var valid_617628 = header.getOrDefault("X-Amz-Date")
  valid_617628 = validateParameter(valid_617628, JString, required = false,
                                 default = nil)
  if valid_617628 != nil:
    section.add "X-Amz-Date", valid_617628
  var valid_617629 = header.getOrDefault("X-Amz-Security-Token")
  valid_617629 = validateParameter(valid_617629, JString, required = false,
                                 default = nil)
  if valid_617629 != nil:
    section.add "X-Amz-Security-Token", valid_617629
  var valid_617630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617630 = validateParameter(valid_617630, JString, required = false,
                                 default = nil)
  if valid_617630 != nil:
    section.add "X-Amz-Content-Sha256", valid_617630
  var valid_617631 = header.getOrDefault("X-Amz-Algorithm")
  valid_617631 = validateParameter(valid_617631, JString, required = false,
                                 default = nil)
  if valid_617631 != nil:
    section.add "X-Amz-Algorithm", valid_617631
  var valid_617632 = header.getOrDefault("X-Amz-Signature")
  valid_617632 = validateParameter(valid_617632, JString, required = false,
                                 default = nil)
  if valid_617632 != nil:
    section.add "X-Amz-Signature", valid_617632
  var valid_617633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617633 = validateParameter(valid_617633, JString, required = false,
                                 default = nil)
  if valid_617633 != nil:
    section.add "X-Amz-SignedHeaders", valid_617633
  var valid_617634 = header.getOrDefault("X-Amz-Credential")
  valid_617634 = validateParameter(valid_617634, JString, required = false,
                                 default = nil)
  if valid_617634 != nil:
    section.add "X-Amz-Credential", valid_617634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617636: Call_UpdateApplication_617624; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an application.
  ## 
  let valid = call_617636.validator(path, query, header, formData, body, _)
  let scheme = call_617636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617636.url(scheme.get, call_617636.host, call_617636.base,
                         call_617636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617636, url, valid, _)

proc call*(call_617637: Call_UpdateApplication_617624; ApplicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates an application.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_617638 = newJObject()
  var body_617639 = newJObject()
  add(path_617638, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_617639 = body
  result = call_617637.call(path_617638, nil, nil, nil, body_617639)

var updateApplication* = Call_UpdateApplication_617624(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_UpdateApplication_617625,
    base: "/", url: url_UpdateApplication_617626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_617610 = ref object of OpenApiRestCall_616866
proc url_DeleteApplication_617612(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApplication_617611(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617613 = path.getOrDefault("ApplicationId")
  valid_617613 = validateParameter(valid_617613, JString, required = true,
                                 default = nil)
  if valid_617613 != nil:
    section.add "ApplicationId", valid_617613
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
  var valid_617614 = header.getOrDefault("X-Amz-Date")
  valid_617614 = validateParameter(valid_617614, JString, required = false,
                                 default = nil)
  if valid_617614 != nil:
    section.add "X-Amz-Date", valid_617614
  var valid_617615 = header.getOrDefault("X-Amz-Security-Token")
  valid_617615 = validateParameter(valid_617615, JString, required = false,
                                 default = nil)
  if valid_617615 != nil:
    section.add "X-Amz-Security-Token", valid_617615
  var valid_617616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617616 = validateParameter(valid_617616, JString, required = false,
                                 default = nil)
  if valid_617616 != nil:
    section.add "X-Amz-Content-Sha256", valid_617616
  var valid_617617 = header.getOrDefault("X-Amz-Algorithm")
  valid_617617 = validateParameter(valid_617617, JString, required = false,
                                 default = nil)
  if valid_617617 != nil:
    section.add "X-Amz-Algorithm", valid_617617
  var valid_617618 = header.getOrDefault("X-Amz-Signature")
  valid_617618 = validateParameter(valid_617618, JString, required = false,
                                 default = nil)
  if valid_617618 != nil:
    section.add "X-Amz-Signature", valid_617618
  var valid_617619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617619 = validateParameter(valid_617619, JString, required = false,
                                 default = nil)
  if valid_617619 != nil:
    section.add "X-Amz-SignedHeaders", valid_617619
  var valid_617620 = header.getOrDefault("X-Amz-Credential")
  valid_617620 = validateParameter(valid_617620, JString, required = false,
                                 default = nil)
  if valid_617620 != nil:
    section.add "X-Amz-Credential", valid_617620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617621: Call_DeleteApplication_617610; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ## 
  let valid = call_617621.validator(path, query, header, formData, body, _)
  let scheme = call_617621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617621.url(scheme.get, call_617621.host, call_617621.base,
                         call_617621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617621, url, valid, _)

proc call*(call_617622: Call_DeleteApplication_617610; ApplicationId: string): Recallable =
  ## deleteApplication
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The ID of the application to delete.
  var path_617623 = newJObject()
  add(path_617623, "ApplicationId", newJString(ApplicationId))
  result = call_617622.call(path_617623, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_617610(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_DeleteApplication_617611,
    base: "/", url: url_DeleteApplication_617612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationProfile_617640 = ref object of OpenApiRestCall_616866
proc url_GetConfigurationProfile_617642(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_GetConfigurationProfile_617641(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieve information about a configuration profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationProfileId: JString (required)
  ##                         : The ID of the configuration profile you want to get.
  ##   ApplicationId: JString (required)
  ##                : The ID of the application that includes the configuration profile you want to get.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationProfileId` field"
  var valid_617643 = path.getOrDefault("ConfigurationProfileId")
  valid_617643 = validateParameter(valid_617643, JString, required = true,
                                 default = nil)
  if valid_617643 != nil:
    section.add "ConfigurationProfileId", valid_617643
  var valid_617644 = path.getOrDefault("ApplicationId")
  valid_617644 = validateParameter(valid_617644, JString, required = true,
                                 default = nil)
  if valid_617644 != nil:
    section.add "ApplicationId", valid_617644
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
  var valid_617645 = header.getOrDefault("X-Amz-Date")
  valid_617645 = validateParameter(valid_617645, JString, required = false,
                                 default = nil)
  if valid_617645 != nil:
    section.add "X-Amz-Date", valid_617645
  var valid_617646 = header.getOrDefault("X-Amz-Security-Token")
  valid_617646 = validateParameter(valid_617646, JString, required = false,
                                 default = nil)
  if valid_617646 != nil:
    section.add "X-Amz-Security-Token", valid_617646
  var valid_617647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617647 = validateParameter(valid_617647, JString, required = false,
                                 default = nil)
  if valid_617647 != nil:
    section.add "X-Amz-Content-Sha256", valid_617647
  var valid_617648 = header.getOrDefault("X-Amz-Algorithm")
  valid_617648 = validateParameter(valid_617648, JString, required = false,
                                 default = nil)
  if valid_617648 != nil:
    section.add "X-Amz-Algorithm", valid_617648
  var valid_617649 = header.getOrDefault("X-Amz-Signature")
  valid_617649 = validateParameter(valid_617649, JString, required = false,
                                 default = nil)
  if valid_617649 != nil:
    section.add "X-Amz-Signature", valid_617649
  var valid_617650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617650 = validateParameter(valid_617650, JString, required = false,
                                 default = nil)
  if valid_617650 != nil:
    section.add "X-Amz-SignedHeaders", valid_617650
  var valid_617651 = header.getOrDefault("X-Amz-Credential")
  valid_617651 = validateParameter(valid_617651, JString, required = false,
                                 default = nil)
  if valid_617651 != nil:
    section.add "X-Amz-Credential", valid_617651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617652: Call_GetConfigurationProfile_617640; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration profile.
  ## 
  let valid = call_617652.validator(path, query, header, formData, body, _)
  let scheme = call_617652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617652.url(scheme.get, call_617652.host, call_617652.base,
                         call_617652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617652, url, valid, _)

proc call*(call_617653: Call_GetConfigurationProfile_617640;
          ConfigurationProfileId: string; ApplicationId: string): Recallable =
  ## getConfigurationProfile
  ## Retrieve information about a configuration profile.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to get.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the configuration profile you want to get.
  var path_617654 = newJObject()
  add(path_617654, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(path_617654, "ApplicationId", newJString(ApplicationId))
  result = call_617653.call(path_617654, nil, nil, nil, nil)

var getConfigurationProfile* = Call_GetConfigurationProfile_617640(
    name: "getConfigurationProfile", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_GetConfigurationProfile_617641, base: "/",
    url: url_GetConfigurationProfile_617642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationProfile_617670 = ref object of OpenApiRestCall_616866
proc url_UpdateConfigurationProfile_617672(protocol: Scheme; host: string;
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

proc validate_UpdateConfigurationProfile_617671(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Updates a configuration profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationProfileId: JString (required)
  ##                         : The ID of the configuration profile.
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationProfileId` field"
  var valid_617673 = path.getOrDefault("ConfigurationProfileId")
  valid_617673 = validateParameter(valid_617673, JString, required = true,
                                 default = nil)
  if valid_617673 != nil:
    section.add "ConfigurationProfileId", valid_617673
  var valid_617674 = path.getOrDefault("ApplicationId")
  valid_617674 = validateParameter(valid_617674, JString, required = true,
                                 default = nil)
  if valid_617674 != nil:
    section.add "ApplicationId", valid_617674
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
  var valid_617675 = header.getOrDefault("X-Amz-Date")
  valid_617675 = validateParameter(valid_617675, JString, required = false,
                                 default = nil)
  if valid_617675 != nil:
    section.add "X-Amz-Date", valid_617675
  var valid_617676 = header.getOrDefault("X-Amz-Security-Token")
  valid_617676 = validateParameter(valid_617676, JString, required = false,
                                 default = nil)
  if valid_617676 != nil:
    section.add "X-Amz-Security-Token", valid_617676
  var valid_617677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617677 = validateParameter(valid_617677, JString, required = false,
                                 default = nil)
  if valid_617677 != nil:
    section.add "X-Amz-Content-Sha256", valid_617677
  var valid_617678 = header.getOrDefault("X-Amz-Algorithm")
  valid_617678 = validateParameter(valid_617678, JString, required = false,
                                 default = nil)
  if valid_617678 != nil:
    section.add "X-Amz-Algorithm", valid_617678
  var valid_617679 = header.getOrDefault("X-Amz-Signature")
  valid_617679 = validateParameter(valid_617679, JString, required = false,
                                 default = nil)
  if valid_617679 != nil:
    section.add "X-Amz-Signature", valid_617679
  var valid_617680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617680 = validateParameter(valid_617680, JString, required = false,
                                 default = nil)
  if valid_617680 != nil:
    section.add "X-Amz-SignedHeaders", valid_617680
  var valid_617681 = header.getOrDefault("X-Amz-Credential")
  valid_617681 = validateParameter(valid_617681, JString, required = false,
                                 default = nil)
  if valid_617681 != nil:
    section.add "X-Amz-Credential", valid_617681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617683: Call_UpdateConfigurationProfile_617670;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a configuration profile.
  ## 
  let valid = call_617683.validator(path, query, header, formData, body, _)
  let scheme = call_617683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617683.url(scheme.get, call_617683.host, call_617683.base,
                         call_617683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617683, url, valid, _)

proc call*(call_617684: Call_UpdateConfigurationProfile_617670;
          ConfigurationProfileId: string; ApplicationId: string; body: JsonNode): Recallable =
  ## updateConfigurationProfile
  ## Updates a configuration profile.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_617685 = newJObject()
  var body_617686 = newJObject()
  add(path_617685, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(path_617685, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_617686 = body
  result = call_617684.call(path_617685, nil, nil, nil, body_617686)

var updateConfigurationProfile* = Call_UpdateConfigurationProfile_617670(
    name: "updateConfigurationProfile", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_UpdateConfigurationProfile_617671, base: "/",
    url: url_UpdateConfigurationProfile_617672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationProfile_617655 = ref object of OpenApiRestCall_616866
proc url_DeleteConfigurationProfile_617657(protocol: Scheme; host: string;
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

proc validate_DeleteConfigurationProfile_617656(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationProfileId: JString (required)
  ##                         : The ID of the configuration profile you want to delete.
  ##   ApplicationId: JString (required)
  ##                : The application ID that includes the configuration profile you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationProfileId` field"
  var valid_617658 = path.getOrDefault("ConfigurationProfileId")
  valid_617658 = validateParameter(valid_617658, JString, required = true,
                                 default = nil)
  if valid_617658 != nil:
    section.add "ConfigurationProfileId", valid_617658
  var valid_617659 = path.getOrDefault("ApplicationId")
  valid_617659 = validateParameter(valid_617659, JString, required = true,
                                 default = nil)
  if valid_617659 != nil:
    section.add "ApplicationId", valid_617659
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
  var valid_617660 = header.getOrDefault("X-Amz-Date")
  valid_617660 = validateParameter(valid_617660, JString, required = false,
                                 default = nil)
  if valid_617660 != nil:
    section.add "X-Amz-Date", valid_617660
  var valid_617661 = header.getOrDefault("X-Amz-Security-Token")
  valid_617661 = validateParameter(valid_617661, JString, required = false,
                                 default = nil)
  if valid_617661 != nil:
    section.add "X-Amz-Security-Token", valid_617661
  var valid_617662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617662 = validateParameter(valid_617662, JString, required = false,
                                 default = nil)
  if valid_617662 != nil:
    section.add "X-Amz-Content-Sha256", valid_617662
  var valid_617663 = header.getOrDefault("X-Amz-Algorithm")
  valid_617663 = validateParameter(valid_617663, JString, required = false,
                                 default = nil)
  if valid_617663 != nil:
    section.add "X-Amz-Algorithm", valid_617663
  var valid_617664 = header.getOrDefault("X-Amz-Signature")
  valid_617664 = validateParameter(valid_617664, JString, required = false,
                                 default = nil)
  if valid_617664 != nil:
    section.add "X-Amz-Signature", valid_617664
  var valid_617665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617665 = validateParameter(valid_617665, JString, required = false,
                                 default = nil)
  if valid_617665 != nil:
    section.add "X-Amz-SignedHeaders", valid_617665
  var valid_617666 = header.getOrDefault("X-Amz-Credential")
  valid_617666 = validateParameter(valid_617666, JString, required = false,
                                 default = nil)
  if valid_617666 != nil:
    section.add "X-Amz-Credential", valid_617666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617667: Call_DeleteConfigurationProfile_617655;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ## 
  let valid = call_617667.validator(path, query, header, formData, body, _)
  let scheme = call_617667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617667.url(scheme.get, call_617667.host, call_617667.base,
                         call_617667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617667, url, valid, _)

proc call*(call_617668: Call_DeleteConfigurationProfile_617655;
          ConfigurationProfileId: string; ApplicationId: string): Recallable =
  ## deleteConfigurationProfile
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to delete.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the configuration profile you want to delete.
  var path_617669 = newJObject()
  add(path_617669, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(path_617669, "ApplicationId", newJString(ApplicationId))
  result = call_617668.call(path_617669, nil, nil, nil, nil)

var deleteConfigurationProfile* = Call_DeleteConfigurationProfile_617655(
    name: "deleteConfigurationProfile", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_DeleteConfigurationProfile_617656, base: "/",
    url: url_DeleteConfigurationProfile_617657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentStrategy_617687 = ref object of OpenApiRestCall_616866
proc url_DeleteDeploymentStrategy_617689(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_DeleteDeploymentStrategy_617688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The ID of the deployment strategy you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_617690 = path.getOrDefault("DeploymentStrategyId")
  valid_617690 = validateParameter(valid_617690, JString, required = true,
                                 default = nil)
  if valid_617690 != nil:
    section.add "DeploymentStrategyId", valid_617690
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
  var valid_617691 = header.getOrDefault("X-Amz-Date")
  valid_617691 = validateParameter(valid_617691, JString, required = false,
                                 default = nil)
  if valid_617691 != nil:
    section.add "X-Amz-Date", valid_617691
  var valid_617692 = header.getOrDefault("X-Amz-Security-Token")
  valid_617692 = validateParameter(valid_617692, JString, required = false,
                                 default = nil)
  if valid_617692 != nil:
    section.add "X-Amz-Security-Token", valid_617692
  var valid_617693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617693 = validateParameter(valid_617693, JString, required = false,
                                 default = nil)
  if valid_617693 != nil:
    section.add "X-Amz-Content-Sha256", valid_617693
  var valid_617694 = header.getOrDefault("X-Amz-Algorithm")
  valid_617694 = validateParameter(valid_617694, JString, required = false,
                                 default = nil)
  if valid_617694 != nil:
    section.add "X-Amz-Algorithm", valid_617694
  var valid_617695 = header.getOrDefault("X-Amz-Signature")
  valid_617695 = validateParameter(valid_617695, JString, required = false,
                                 default = nil)
  if valid_617695 != nil:
    section.add "X-Amz-Signature", valid_617695
  var valid_617696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617696 = validateParameter(valid_617696, JString, required = false,
                                 default = nil)
  if valid_617696 != nil:
    section.add "X-Amz-SignedHeaders", valid_617696
  var valid_617697 = header.getOrDefault("X-Amz-Credential")
  valid_617697 = validateParameter(valid_617697, JString, required = false,
                                 default = nil)
  if valid_617697 != nil:
    section.add "X-Amz-Credential", valid_617697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617698: Call_DeleteDeploymentStrategy_617687; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  let valid = call_617698.validator(path, query, header, formData, body, _)
  let scheme = call_617698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617698.url(scheme.get, call_617698.host, call_617698.base,
                         call_617698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617698, url, valid, _)

proc call*(call_617699: Call_DeleteDeploymentStrategy_617687;
          DeploymentStrategyId: string): Recallable =
  ## deleteDeploymentStrategy
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy you want to delete.
  var path_617700 = newJObject()
  add(path_617700, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_617699.call(path_617700, nil, nil, nil, nil)

var deleteDeploymentStrategy* = Call_DeleteDeploymentStrategy_617687(
    name: "deleteDeploymentStrategy", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com",
    route: "/deployementstrategies/{DeploymentStrategyId}",
    validator: validate_DeleteDeploymentStrategy_617688, base: "/",
    url: url_DeleteDeploymentStrategy_617689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnvironment_617701 = ref object of OpenApiRestCall_616866
proc url_GetEnvironment_617703(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnvironment_617702(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The ID of the application that includes the environment you want to get.
  ##   EnvironmentId: JString (required)
  ##                : The ID of the environment you wnat to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_617704 = path.getOrDefault("ApplicationId")
  valid_617704 = validateParameter(valid_617704, JString, required = true,
                                 default = nil)
  if valid_617704 != nil:
    section.add "ApplicationId", valid_617704
  var valid_617705 = path.getOrDefault("EnvironmentId")
  valid_617705 = validateParameter(valid_617705, JString, required = true,
                                 default = nil)
  if valid_617705 != nil:
    section.add "EnvironmentId", valid_617705
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
  var valid_617706 = header.getOrDefault("X-Amz-Date")
  valid_617706 = validateParameter(valid_617706, JString, required = false,
                                 default = nil)
  if valid_617706 != nil:
    section.add "X-Amz-Date", valid_617706
  var valid_617707 = header.getOrDefault("X-Amz-Security-Token")
  valid_617707 = validateParameter(valid_617707, JString, required = false,
                                 default = nil)
  if valid_617707 != nil:
    section.add "X-Amz-Security-Token", valid_617707
  var valid_617708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617708 = validateParameter(valid_617708, JString, required = false,
                                 default = nil)
  if valid_617708 != nil:
    section.add "X-Amz-Content-Sha256", valid_617708
  var valid_617709 = header.getOrDefault("X-Amz-Algorithm")
  valid_617709 = validateParameter(valid_617709, JString, required = false,
                                 default = nil)
  if valid_617709 != nil:
    section.add "X-Amz-Algorithm", valid_617709
  var valid_617710 = header.getOrDefault("X-Amz-Signature")
  valid_617710 = validateParameter(valid_617710, JString, required = false,
                                 default = nil)
  if valid_617710 != nil:
    section.add "X-Amz-Signature", valid_617710
  var valid_617711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617711 = validateParameter(valid_617711, JString, required = false,
                                 default = nil)
  if valid_617711 != nil:
    section.add "X-Amz-SignedHeaders", valid_617711
  var valid_617712 = header.getOrDefault("X-Amz-Credential")
  valid_617712 = validateParameter(valid_617712, JString, required = false,
                                 default = nil)
  if valid_617712 != nil:
    section.add "X-Amz-Credential", valid_617712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617713: Call_GetEnvironment_617701; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ## 
  let valid = call_617713.validator(path, query, header, formData, body, _)
  let scheme = call_617713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617713.url(scheme.get, call_617713.host, call_617713.base,
                         call_617713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617713, url, valid, _)

proc call*(call_617714: Call_GetEnvironment_617701; ApplicationId: string;
          EnvironmentId: string): Recallable =
  ## getEnvironment
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the environment you want to get.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you wnat to get.
  var path_617715 = newJObject()
  add(path_617715, "ApplicationId", newJString(ApplicationId))
  add(path_617715, "EnvironmentId", newJString(EnvironmentId))
  result = call_617714.call(path_617715, nil, nil, nil, nil)

var getEnvironment* = Call_GetEnvironment_617701(name: "getEnvironment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_GetEnvironment_617702, base: "/", url: url_GetEnvironment_617703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_617731 = ref object of OpenApiRestCall_616866
proc url_UpdateEnvironment_617733(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEnvironment_617732(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## Updates an environment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_617734 = path.getOrDefault("ApplicationId")
  valid_617734 = validateParameter(valid_617734, JString, required = true,
                                 default = nil)
  if valid_617734 != nil:
    section.add "ApplicationId", valid_617734
  var valid_617735 = path.getOrDefault("EnvironmentId")
  valid_617735 = validateParameter(valid_617735, JString, required = true,
                                 default = nil)
  if valid_617735 != nil:
    section.add "EnvironmentId", valid_617735
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
  var valid_617736 = header.getOrDefault("X-Amz-Date")
  valid_617736 = validateParameter(valid_617736, JString, required = false,
                                 default = nil)
  if valid_617736 != nil:
    section.add "X-Amz-Date", valid_617736
  var valid_617737 = header.getOrDefault("X-Amz-Security-Token")
  valid_617737 = validateParameter(valid_617737, JString, required = false,
                                 default = nil)
  if valid_617737 != nil:
    section.add "X-Amz-Security-Token", valid_617737
  var valid_617738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617738 = validateParameter(valid_617738, JString, required = false,
                                 default = nil)
  if valid_617738 != nil:
    section.add "X-Amz-Content-Sha256", valid_617738
  var valid_617739 = header.getOrDefault("X-Amz-Algorithm")
  valid_617739 = validateParameter(valid_617739, JString, required = false,
                                 default = nil)
  if valid_617739 != nil:
    section.add "X-Amz-Algorithm", valid_617739
  var valid_617740 = header.getOrDefault("X-Amz-Signature")
  valid_617740 = validateParameter(valid_617740, JString, required = false,
                                 default = nil)
  if valid_617740 != nil:
    section.add "X-Amz-Signature", valid_617740
  var valid_617741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617741 = validateParameter(valid_617741, JString, required = false,
                                 default = nil)
  if valid_617741 != nil:
    section.add "X-Amz-SignedHeaders", valid_617741
  var valid_617742 = header.getOrDefault("X-Amz-Credential")
  valid_617742 = validateParameter(valid_617742, JString, required = false,
                                 default = nil)
  if valid_617742 != nil:
    section.add "X-Amz-Credential", valid_617742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617744: Call_UpdateEnvironment_617731; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an environment.
  ## 
  let valid = call_617744.validator(path, query, header, formData, body, _)
  let scheme = call_617744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617744.url(scheme.get, call_617744.host, call_617744.base,
                         call_617744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617744, url, valid, _)

proc call*(call_617745: Call_UpdateEnvironment_617731; ApplicationId: string;
          body: JsonNode; EnvironmentId: string): Recallable =
  ## updateEnvironment
  ## Updates an environment.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_617746 = newJObject()
  var body_617747 = newJObject()
  add(path_617746, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_617747 = body
  add(path_617746, "EnvironmentId", newJString(EnvironmentId))
  result = call_617745.call(path_617746, nil, nil, nil, body_617747)

var updateEnvironment* = Call_UpdateEnvironment_617731(name: "updateEnvironment",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_UpdateEnvironment_617732, base: "/",
    url: url_UpdateEnvironment_617733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_617716 = ref object of OpenApiRestCall_616866
proc url_DeleteEnvironment_617718(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEnvironment_617717(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The application ID that includes the environment you want to delete.
  ##   EnvironmentId: JString (required)
  ##                : The ID of the environment you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_617719 = path.getOrDefault("ApplicationId")
  valid_617719 = validateParameter(valid_617719, JString, required = true,
                                 default = nil)
  if valid_617719 != nil:
    section.add "ApplicationId", valid_617719
  var valid_617720 = path.getOrDefault("EnvironmentId")
  valid_617720 = validateParameter(valid_617720, JString, required = true,
                                 default = nil)
  if valid_617720 != nil:
    section.add "EnvironmentId", valid_617720
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
  var valid_617721 = header.getOrDefault("X-Amz-Date")
  valid_617721 = validateParameter(valid_617721, JString, required = false,
                                 default = nil)
  if valid_617721 != nil:
    section.add "X-Amz-Date", valid_617721
  var valid_617722 = header.getOrDefault("X-Amz-Security-Token")
  valid_617722 = validateParameter(valid_617722, JString, required = false,
                                 default = nil)
  if valid_617722 != nil:
    section.add "X-Amz-Security-Token", valid_617722
  var valid_617723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617723 = validateParameter(valid_617723, JString, required = false,
                                 default = nil)
  if valid_617723 != nil:
    section.add "X-Amz-Content-Sha256", valid_617723
  var valid_617724 = header.getOrDefault("X-Amz-Algorithm")
  valid_617724 = validateParameter(valid_617724, JString, required = false,
                                 default = nil)
  if valid_617724 != nil:
    section.add "X-Amz-Algorithm", valid_617724
  var valid_617725 = header.getOrDefault("X-Amz-Signature")
  valid_617725 = validateParameter(valid_617725, JString, required = false,
                                 default = nil)
  if valid_617725 != nil:
    section.add "X-Amz-Signature", valid_617725
  var valid_617726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617726 = validateParameter(valid_617726, JString, required = false,
                                 default = nil)
  if valid_617726 != nil:
    section.add "X-Amz-SignedHeaders", valid_617726
  var valid_617727 = header.getOrDefault("X-Amz-Credential")
  valid_617727 = validateParameter(valid_617727, JString, required = false,
                                 default = nil)
  if valid_617727 != nil:
    section.add "X-Amz-Credential", valid_617727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617728: Call_DeleteEnvironment_617716; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ## 
  let valid = call_617728.validator(path, query, header, formData, body, _)
  let scheme = call_617728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617728.url(scheme.get, call_617728.host, call_617728.base,
                         call_617728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617728, url, valid, _)

proc call*(call_617729: Call_DeleteEnvironment_617716; ApplicationId: string;
          EnvironmentId: string): Recallable =
  ## deleteEnvironment
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the environment you want to delete.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you want to delete.
  var path_617730 = newJObject()
  add(path_617730, "ApplicationId", newJString(ApplicationId))
  add(path_617730, "EnvironmentId", newJString(EnvironmentId))
  result = call_617729.call(path_617730, nil, nil, nil, nil)

var deleteEnvironment* = Call_DeleteEnvironment_617716(name: "deleteEnvironment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_DeleteEnvironment_617717, base: "/",
    url: url_DeleteEnvironment_617718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfiguration_617748 = ref object of OpenApiRestCall_616866
proc url_GetConfiguration_617750(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetConfiguration_617749(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode =
  ## Retrieve information about a configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Configuration: JString (required)
  ##                : The configuration to get.
  ##   Application: JString (required)
  ##              : The application to get.
  ##   Environment: JString (required)
  ##              : The environment to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `Configuration` field"
  var valid_617751 = path.getOrDefault("Configuration")
  valid_617751 = validateParameter(valid_617751, JString, required = true,
                                 default = nil)
  if valid_617751 != nil:
    section.add "Configuration", valid_617751
  var valid_617752 = path.getOrDefault("Application")
  valid_617752 = validateParameter(valid_617752, JString, required = true,
                                 default = nil)
  if valid_617752 != nil:
    section.add "Application", valid_617752
  var valid_617753 = path.getOrDefault("Environment")
  valid_617753 = validateParameter(valid_617753, JString, required = true,
                                 default = nil)
  if valid_617753 != nil:
    section.add "Environment", valid_617753
  result.add "path", section
  ## parameters in `query` object:
  ##   client_id: JString (required)
  ##            : A unique ID to identify the client for the configuration. This ID enables AppConfig to deploy the configuration in intervals, as defined in the deployment strategy.
  ##   client_configuration_version: JString
  ##                               : The configuration version returned in the most recent GetConfiguration response.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `client_id` field"
  var valid_617754 = query.getOrDefault("client_id")
  valid_617754 = validateParameter(valid_617754, JString, required = true,
                                 default = nil)
  if valid_617754 != nil:
    section.add "client_id", valid_617754
  var valid_617755 = query.getOrDefault("client_configuration_version")
  valid_617755 = validateParameter(valid_617755, JString, required = false,
                                 default = nil)
  if valid_617755 != nil:
    section.add "client_configuration_version", valid_617755
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
  var valid_617756 = header.getOrDefault("X-Amz-Date")
  valid_617756 = validateParameter(valid_617756, JString, required = false,
                                 default = nil)
  if valid_617756 != nil:
    section.add "X-Amz-Date", valid_617756
  var valid_617757 = header.getOrDefault("X-Amz-Security-Token")
  valid_617757 = validateParameter(valid_617757, JString, required = false,
                                 default = nil)
  if valid_617757 != nil:
    section.add "X-Amz-Security-Token", valid_617757
  var valid_617758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617758 = validateParameter(valid_617758, JString, required = false,
                                 default = nil)
  if valid_617758 != nil:
    section.add "X-Amz-Content-Sha256", valid_617758
  var valid_617759 = header.getOrDefault("X-Amz-Algorithm")
  valid_617759 = validateParameter(valid_617759, JString, required = false,
                                 default = nil)
  if valid_617759 != nil:
    section.add "X-Amz-Algorithm", valid_617759
  var valid_617760 = header.getOrDefault("X-Amz-Signature")
  valid_617760 = validateParameter(valid_617760, JString, required = false,
                                 default = nil)
  if valid_617760 != nil:
    section.add "X-Amz-Signature", valid_617760
  var valid_617761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617761 = validateParameter(valid_617761, JString, required = false,
                                 default = nil)
  if valid_617761 != nil:
    section.add "X-Amz-SignedHeaders", valid_617761
  var valid_617762 = header.getOrDefault("X-Amz-Credential")
  valid_617762 = validateParameter(valid_617762, JString, required = false,
                                 default = nil)
  if valid_617762 != nil:
    section.add "X-Amz-Credential", valid_617762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617763: Call_GetConfiguration_617748; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration.
  ## 
  let valid = call_617763.validator(path, query, header, formData, body, _)
  let scheme = call_617763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617763.url(scheme.get, call_617763.host, call_617763.base,
                         call_617763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617763, url, valid, _)

proc call*(call_617764: Call_GetConfiguration_617748; clientId: string;
          Configuration: string; Application: string; Environment: string;
          clientConfigurationVersion: string = ""): Recallable =
  ## getConfiguration
  ## Retrieve information about a configuration.
  ##   clientId: string (required)
  ##           : A unique ID to identify the client for the configuration. This ID enables AppConfig to deploy the configuration in intervals, as defined in the deployment strategy.
  ##   Configuration: string (required)
  ##                : The configuration to get.
  ##   Application: string (required)
  ##              : The application to get.
  ##   Environment: string (required)
  ##              : The environment to get.
  ##   clientConfigurationVersion: string
  ##                             : The configuration version returned in the most recent GetConfiguration response.
  var path_617765 = newJObject()
  var query_617766 = newJObject()
  add(query_617766, "client_id", newJString(clientId))
  add(path_617765, "Configuration", newJString(Configuration))
  add(path_617765, "Application", newJString(Application))
  add(path_617765, "Environment", newJString(Environment))
  add(query_617766, "client_configuration_version",
      newJString(clientConfigurationVersion))
  result = call_617764.call(path_617765, query_617766, nil, nil, nil)

var getConfiguration* = Call_GetConfiguration_617748(name: "getConfiguration",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{Application}/environments/{Environment}/configurations/{Configuration}#client_id",
    validator: validate_GetConfiguration_617749, base: "/",
    url: url_GetConfiguration_617750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_617767 = ref object of OpenApiRestCall_616866
proc url_GetDeployment_617769(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_617768(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieve information about a configuration deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentNumber: JInt (required)
  ##                   : The sequence number of the deployment.
  ##   ApplicationId: JString (required)
  ##                : The ID of the application that includes the deployment you want to get. 
  ##   EnvironmentId: JString (required)
  ##                : The ID of the environment that includes the deployment you want to get. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeploymentNumber` field"
  var valid_617770 = path.getOrDefault("DeploymentNumber")
  valid_617770 = validateParameter(valid_617770, JInt, required = true, default = nil)
  if valid_617770 != nil:
    section.add "DeploymentNumber", valid_617770
  var valid_617771 = path.getOrDefault("ApplicationId")
  valid_617771 = validateParameter(valid_617771, JString, required = true,
                                 default = nil)
  if valid_617771 != nil:
    section.add "ApplicationId", valid_617771
  var valid_617772 = path.getOrDefault("EnvironmentId")
  valid_617772 = validateParameter(valid_617772, JString, required = true,
                                 default = nil)
  if valid_617772 != nil:
    section.add "EnvironmentId", valid_617772
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
  var valid_617773 = header.getOrDefault("X-Amz-Date")
  valid_617773 = validateParameter(valid_617773, JString, required = false,
                                 default = nil)
  if valid_617773 != nil:
    section.add "X-Amz-Date", valid_617773
  var valid_617774 = header.getOrDefault("X-Amz-Security-Token")
  valid_617774 = validateParameter(valid_617774, JString, required = false,
                                 default = nil)
  if valid_617774 != nil:
    section.add "X-Amz-Security-Token", valid_617774
  var valid_617775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617775 = validateParameter(valid_617775, JString, required = false,
                                 default = nil)
  if valid_617775 != nil:
    section.add "X-Amz-Content-Sha256", valid_617775
  var valid_617776 = header.getOrDefault("X-Amz-Algorithm")
  valid_617776 = validateParameter(valid_617776, JString, required = false,
                                 default = nil)
  if valid_617776 != nil:
    section.add "X-Amz-Algorithm", valid_617776
  var valid_617777 = header.getOrDefault("X-Amz-Signature")
  valid_617777 = validateParameter(valid_617777, JString, required = false,
                                 default = nil)
  if valid_617777 != nil:
    section.add "X-Amz-Signature", valid_617777
  var valid_617778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617778 = validateParameter(valid_617778, JString, required = false,
                                 default = nil)
  if valid_617778 != nil:
    section.add "X-Amz-SignedHeaders", valid_617778
  var valid_617779 = header.getOrDefault("X-Amz-Credential")
  valid_617779 = validateParameter(valid_617779, JString, required = false,
                                 default = nil)
  if valid_617779 != nil:
    section.add "X-Amz-Credential", valid_617779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617780: Call_GetDeployment_617767; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration deployment.
  ## 
  let valid = call_617780.validator(path, query, header, formData, body, _)
  let scheme = call_617780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617780.url(scheme.get, call_617780.host, call_617780.base,
                         call_617780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617780, url, valid, _)

proc call*(call_617781: Call_GetDeployment_617767; DeploymentNumber: int;
          ApplicationId: string; EnvironmentId: string): Recallable =
  ## getDeployment
  ## Retrieve information about a configuration deployment.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the deployment you want to get. 
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment that includes the deployment you want to get. 
  var path_617782 = newJObject()
  add(path_617782, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_617782, "ApplicationId", newJString(ApplicationId))
  add(path_617782, "EnvironmentId", newJString(EnvironmentId))
  result = call_617781.call(path_617782, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_617767(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_GetDeployment_617768, base: "/", url: url_GetDeployment_617769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_617783 = ref object of OpenApiRestCall_616866
proc url_StopDeployment_617785(protocol: Scheme; host: string; base: string;
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

proc validate_StopDeployment_617784(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentNumber: JInt (required)
  ##                   : The sequence number of the deployment.
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeploymentNumber` field"
  var valid_617786 = path.getOrDefault("DeploymentNumber")
  valid_617786 = validateParameter(valid_617786, JInt, required = true, default = nil)
  if valid_617786 != nil:
    section.add "DeploymentNumber", valid_617786
  var valid_617787 = path.getOrDefault("ApplicationId")
  valid_617787 = validateParameter(valid_617787, JString, required = true,
                                 default = nil)
  if valid_617787 != nil:
    section.add "ApplicationId", valid_617787
  var valid_617788 = path.getOrDefault("EnvironmentId")
  valid_617788 = validateParameter(valid_617788, JString, required = true,
                                 default = nil)
  if valid_617788 != nil:
    section.add "EnvironmentId", valid_617788
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
  var valid_617789 = header.getOrDefault("X-Amz-Date")
  valid_617789 = validateParameter(valid_617789, JString, required = false,
                                 default = nil)
  if valid_617789 != nil:
    section.add "X-Amz-Date", valid_617789
  var valid_617790 = header.getOrDefault("X-Amz-Security-Token")
  valid_617790 = validateParameter(valid_617790, JString, required = false,
                                 default = nil)
  if valid_617790 != nil:
    section.add "X-Amz-Security-Token", valid_617790
  var valid_617791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617791 = validateParameter(valid_617791, JString, required = false,
                                 default = nil)
  if valid_617791 != nil:
    section.add "X-Amz-Content-Sha256", valid_617791
  var valid_617792 = header.getOrDefault("X-Amz-Algorithm")
  valid_617792 = validateParameter(valid_617792, JString, required = false,
                                 default = nil)
  if valid_617792 != nil:
    section.add "X-Amz-Algorithm", valid_617792
  var valid_617793 = header.getOrDefault("X-Amz-Signature")
  valid_617793 = validateParameter(valid_617793, JString, required = false,
                                 default = nil)
  if valid_617793 != nil:
    section.add "X-Amz-Signature", valid_617793
  var valid_617794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617794 = validateParameter(valid_617794, JString, required = false,
                                 default = nil)
  if valid_617794 != nil:
    section.add "X-Amz-SignedHeaders", valid_617794
  var valid_617795 = header.getOrDefault("X-Amz-Credential")
  valid_617795 = validateParameter(valid_617795, JString, required = false,
                                 default = nil)
  if valid_617795 != nil:
    section.add "X-Amz-Credential", valid_617795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617796: Call_StopDeployment_617783; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ## 
  let valid = call_617796.validator(path, query, header, formData, body, _)
  let scheme = call_617796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617796.url(scheme.get, call_617796.host, call_617796.base,
                         call_617796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617796, url, valid, _)

proc call*(call_617797: Call_StopDeployment_617783; DeploymentNumber: int;
          ApplicationId: string; EnvironmentId: string): Recallable =
  ## stopDeployment
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_617798 = newJObject()
  add(path_617798, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_617798, "ApplicationId", newJString(ApplicationId))
  add(path_617798, "EnvironmentId", newJString(EnvironmentId))
  result = call_617797.call(path_617798, nil, nil, nil, nil)

var stopDeployment* = Call_StopDeployment_617783(name: "stopDeployment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_StopDeployment_617784, base: "/", url: url_StopDeployment_617785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStrategy_617799 = ref object of OpenApiRestCall_616866
proc url_GetDeploymentStrategy_617801(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetDeploymentStrategy_617800(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The ID of the deployment strategy to get.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_617802 = path.getOrDefault("DeploymentStrategyId")
  valid_617802 = validateParameter(valid_617802, JString, required = true,
                                 default = nil)
  if valid_617802 != nil:
    section.add "DeploymentStrategyId", valid_617802
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
  var valid_617803 = header.getOrDefault("X-Amz-Date")
  valid_617803 = validateParameter(valid_617803, JString, required = false,
                                 default = nil)
  if valid_617803 != nil:
    section.add "X-Amz-Date", valid_617803
  var valid_617804 = header.getOrDefault("X-Amz-Security-Token")
  valid_617804 = validateParameter(valid_617804, JString, required = false,
                                 default = nil)
  if valid_617804 != nil:
    section.add "X-Amz-Security-Token", valid_617804
  var valid_617805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617805 = validateParameter(valid_617805, JString, required = false,
                                 default = nil)
  if valid_617805 != nil:
    section.add "X-Amz-Content-Sha256", valid_617805
  var valid_617806 = header.getOrDefault("X-Amz-Algorithm")
  valid_617806 = validateParameter(valid_617806, JString, required = false,
                                 default = nil)
  if valid_617806 != nil:
    section.add "X-Amz-Algorithm", valid_617806
  var valid_617807 = header.getOrDefault("X-Amz-Signature")
  valid_617807 = validateParameter(valid_617807, JString, required = false,
                                 default = nil)
  if valid_617807 != nil:
    section.add "X-Amz-Signature", valid_617807
  var valid_617808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617808 = validateParameter(valid_617808, JString, required = false,
                                 default = nil)
  if valid_617808 != nil:
    section.add "X-Amz-SignedHeaders", valid_617808
  var valid_617809 = header.getOrDefault("X-Amz-Credential")
  valid_617809 = validateParameter(valid_617809, JString, required = false,
                                 default = nil)
  if valid_617809 != nil:
    section.add "X-Amz-Credential", valid_617809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617810: Call_GetDeploymentStrategy_617799; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_617810.validator(path, query, header, formData, body, _)
  let scheme = call_617810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617810.url(scheme.get, call_617810.host, call_617810.base,
                         call_617810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617810, url, valid, _)

proc call*(call_617811: Call_GetDeploymentStrategy_617799;
          DeploymentStrategyId: string): Recallable =
  ## getDeploymentStrategy
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy to get.
  var path_617812 = newJObject()
  add(path_617812, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_617811.call(path_617812, nil, nil, nil, nil)

var getDeploymentStrategy* = Call_GetDeploymentStrategy_617799(
    name: "getDeploymentStrategy", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_GetDeploymentStrategy_617800, base: "/",
    url: url_GetDeploymentStrategy_617801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentStrategy_617813 = ref object of OpenApiRestCall_616866
proc url_UpdateDeploymentStrategy_617815(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_UpdateDeploymentStrategy_617814(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Updates a deployment strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The deployment strategy ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_617816 = path.getOrDefault("DeploymentStrategyId")
  valid_617816 = validateParameter(valid_617816, JString, required = true,
                                 default = nil)
  if valid_617816 != nil:
    section.add "DeploymentStrategyId", valid_617816
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
  var valid_617817 = header.getOrDefault("X-Amz-Date")
  valid_617817 = validateParameter(valid_617817, JString, required = false,
                                 default = nil)
  if valid_617817 != nil:
    section.add "X-Amz-Date", valid_617817
  var valid_617818 = header.getOrDefault("X-Amz-Security-Token")
  valid_617818 = validateParameter(valid_617818, JString, required = false,
                                 default = nil)
  if valid_617818 != nil:
    section.add "X-Amz-Security-Token", valid_617818
  var valid_617819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617819 = validateParameter(valid_617819, JString, required = false,
                                 default = nil)
  if valid_617819 != nil:
    section.add "X-Amz-Content-Sha256", valid_617819
  var valid_617820 = header.getOrDefault("X-Amz-Algorithm")
  valid_617820 = validateParameter(valid_617820, JString, required = false,
                                 default = nil)
  if valid_617820 != nil:
    section.add "X-Amz-Algorithm", valid_617820
  var valid_617821 = header.getOrDefault("X-Amz-Signature")
  valid_617821 = validateParameter(valid_617821, JString, required = false,
                                 default = nil)
  if valid_617821 != nil:
    section.add "X-Amz-Signature", valid_617821
  var valid_617822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617822 = validateParameter(valid_617822, JString, required = false,
                                 default = nil)
  if valid_617822 != nil:
    section.add "X-Amz-SignedHeaders", valid_617822
  var valid_617823 = header.getOrDefault("X-Amz-Credential")
  valid_617823 = validateParameter(valid_617823, JString, required = false,
                                 default = nil)
  if valid_617823 != nil:
    section.add "X-Amz-Credential", valid_617823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617825: Call_UpdateDeploymentStrategy_617813; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a deployment strategy.
  ## 
  let valid = call_617825.validator(path, query, header, formData, body, _)
  let scheme = call_617825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617825.url(scheme.get, call_617825.host, call_617825.base,
                         call_617825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617825, url, valid, _)

proc call*(call_617826: Call_UpdateDeploymentStrategy_617813;
          DeploymentStrategyId: string; body: JsonNode): Recallable =
  ## updateDeploymentStrategy
  ## Updates a deployment strategy.
  ##   DeploymentStrategyId: string (required)
  ##                       : The deployment strategy ID.
  ##   body: JObject (required)
  var path_617827 = newJObject()
  var body_617828 = newJObject()
  add(path_617827, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  if body != nil:
    body_617828 = body
  result = call_617826.call(path_617827, nil, nil, nil, body_617828)

var updateDeploymentStrategy* = Call_UpdateDeploymentStrategy_617813(
    name: "updateDeploymentStrategy", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_UpdateDeploymentStrategy_617814, base: "/",
    url: url_UpdateDeploymentStrategy_617815, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_617849 = ref object of OpenApiRestCall_616866
proc url_StartDeployment_617851(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "EnvironmentId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDeployment_617850(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Starts a deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_617852 = path.getOrDefault("ApplicationId")
  valid_617852 = validateParameter(valid_617852, JString, required = true,
                                 default = nil)
  if valid_617852 != nil:
    section.add "ApplicationId", valid_617852
  var valid_617853 = path.getOrDefault("EnvironmentId")
  valid_617853 = validateParameter(valid_617853, JString, required = true,
                                 default = nil)
  if valid_617853 != nil:
    section.add "EnvironmentId", valid_617853
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
  var valid_617854 = header.getOrDefault("X-Amz-Date")
  valid_617854 = validateParameter(valid_617854, JString, required = false,
                                 default = nil)
  if valid_617854 != nil:
    section.add "X-Amz-Date", valid_617854
  var valid_617855 = header.getOrDefault("X-Amz-Security-Token")
  valid_617855 = validateParameter(valid_617855, JString, required = false,
                                 default = nil)
  if valid_617855 != nil:
    section.add "X-Amz-Security-Token", valid_617855
  var valid_617856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617856 = validateParameter(valid_617856, JString, required = false,
                                 default = nil)
  if valid_617856 != nil:
    section.add "X-Amz-Content-Sha256", valid_617856
  var valid_617857 = header.getOrDefault("X-Amz-Algorithm")
  valid_617857 = validateParameter(valid_617857, JString, required = false,
                                 default = nil)
  if valid_617857 != nil:
    section.add "X-Amz-Algorithm", valid_617857
  var valid_617858 = header.getOrDefault("X-Amz-Signature")
  valid_617858 = validateParameter(valid_617858, JString, required = false,
                                 default = nil)
  if valid_617858 != nil:
    section.add "X-Amz-Signature", valid_617858
  var valid_617859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617859 = validateParameter(valid_617859, JString, required = false,
                                 default = nil)
  if valid_617859 != nil:
    section.add "X-Amz-SignedHeaders", valid_617859
  var valid_617860 = header.getOrDefault("X-Amz-Credential")
  valid_617860 = validateParameter(valid_617860, JString, required = false,
                                 default = nil)
  if valid_617860 != nil:
    section.add "X-Amz-Credential", valid_617860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617862: Call_StartDeployment_617849; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a deployment.
  ## 
  let valid = call_617862.validator(path, query, header, formData, body, _)
  let scheme = call_617862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617862.url(scheme.get, call_617862.host, call_617862.base,
                         call_617862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617862, url, valid, _)

proc call*(call_617863: Call_StartDeployment_617849; ApplicationId: string;
          body: JsonNode; EnvironmentId: string): Recallable =
  ## startDeployment
  ## Starts a deployment.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_617864 = newJObject()
  var body_617865 = newJObject()
  add(path_617864, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_617865 = body
  add(path_617864, "EnvironmentId", newJString(EnvironmentId))
  result = call_617863.call(path_617864, nil, nil, nil, body_617865)

var startDeployment* = Call_StartDeployment_617849(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_StartDeployment_617850, base: "/", url: url_StartDeployment_617851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_617829 = ref object of OpenApiRestCall_616866
proc url_ListDeployments_617831(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "EnvironmentId"),
               (kind: ConstantSegment, value: "/deployments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeployments_617830(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode =
  ## Lists the deployments for an environment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_617832 = path.getOrDefault("ApplicationId")
  valid_617832 = validateParameter(valid_617832, JString, required = true,
                                 default = nil)
  if valid_617832 != nil:
    section.add "ApplicationId", valid_617832
  var valid_617833 = path.getOrDefault("EnvironmentId")
  valid_617833 = validateParameter(valid_617833, JString, required = true,
                                 default = nil)
  if valid_617833 != nil:
    section.add "EnvironmentId", valid_617833
  result.add "path", section
  ## parameters in `query` object:
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_617834 = query.getOrDefault("next_token")
  valid_617834 = validateParameter(valid_617834, JString, required = false,
                                 default = nil)
  if valid_617834 != nil:
    section.add "next_token", valid_617834
  var valid_617835 = query.getOrDefault("max_results")
  valid_617835 = validateParameter(valid_617835, JInt, required = false, default = nil)
  if valid_617835 != nil:
    section.add "max_results", valid_617835
  var valid_617836 = query.getOrDefault("NextToken")
  valid_617836 = validateParameter(valid_617836, JString, required = false,
                                 default = nil)
  if valid_617836 != nil:
    section.add "NextToken", valid_617836
  var valid_617837 = query.getOrDefault("MaxResults")
  valid_617837 = validateParameter(valid_617837, JString, required = false,
                                 default = nil)
  if valid_617837 != nil:
    section.add "MaxResults", valid_617837
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
  var valid_617838 = header.getOrDefault("X-Amz-Date")
  valid_617838 = validateParameter(valid_617838, JString, required = false,
                                 default = nil)
  if valid_617838 != nil:
    section.add "X-Amz-Date", valid_617838
  var valid_617839 = header.getOrDefault("X-Amz-Security-Token")
  valid_617839 = validateParameter(valid_617839, JString, required = false,
                                 default = nil)
  if valid_617839 != nil:
    section.add "X-Amz-Security-Token", valid_617839
  var valid_617840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617840 = validateParameter(valid_617840, JString, required = false,
                                 default = nil)
  if valid_617840 != nil:
    section.add "X-Amz-Content-Sha256", valid_617840
  var valid_617841 = header.getOrDefault("X-Amz-Algorithm")
  valid_617841 = validateParameter(valid_617841, JString, required = false,
                                 default = nil)
  if valid_617841 != nil:
    section.add "X-Amz-Algorithm", valid_617841
  var valid_617842 = header.getOrDefault("X-Amz-Signature")
  valid_617842 = validateParameter(valid_617842, JString, required = false,
                                 default = nil)
  if valid_617842 != nil:
    section.add "X-Amz-Signature", valid_617842
  var valid_617843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617843 = validateParameter(valid_617843, JString, required = false,
                                 default = nil)
  if valid_617843 != nil:
    section.add "X-Amz-SignedHeaders", valid_617843
  var valid_617844 = header.getOrDefault("X-Amz-Credential")
  valid_617844 = validateParameter(valid_617844, JString, required = false,
                                 default = nil)
  if valid_617844 != nil:
    section.add "X-Amz-Credential", valid_617844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617845: Call_ListDeployments_617829; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the deployments for an environment.
  ## 
  let valid = call_617845.validator(path, query, header, formData, body, _)
  let scheme = call_617845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617845.url(scheme.get, call_617845.host, call_617845.base,
                         call_617845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617845, url, valid, _)

proc call*(call_617846: Call_ListDeployments_617829; ApplicationId: string;
          EnvironmentId: string; nextToken: string = ""; maxResults: int = 0;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDeployments
  ## Lists the deployments for an environment.
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   NextToken: string
  ##            : Pagination token
  ##   MaxResults: string
  ##             : Pagination limit
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_617847 = newJObject()
  var query_617848 = newJObject()
  add(query_617848, "next_token", newJString(nextToken))
  add(path_617847, "ApplicationId", newJString(ApplicationId))
  add(query_617848, "max_results", newJInt(maxResults))
  add(query_617848, "NextToken", newJString(NextToken))
  add(query_617848, "MaxResults", newJString(MaxResults))
  add(path_617847, "EnvironmentId", newJString(EnvironmentId))
  result = call_617846.call(path_617847, query_617848, nil, nil, nil)

var listDeployments* = Call_ListDeployments_617829(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_ListDeployments_617830, base: "/", url: url_ListDeployments_617831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617880 = ref object of OpenApiRestCall_616866
proc url_TagResource_617882(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_617881(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617883 = path.getOrDefault("ResourceArn")
  valid_617883 = validateParameter(valid_617883, JString, required = true,
                                 default = nil)
  if valid_617883 != nil:
    section.add "ResourceArn", valid_617883
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
  var valid_617884 = header.getOrDefault("X-Amz-Date")
  valid_617884 = validateParameter(valid_617884, JString, required = false,
                                 default = nil)
  if valid_617884 != nil:
    section.add "X-Amz-Date", valid_617884
  var valid_617885 = header.getOrDefault("X-Amz-Security-Token")
  valid_617885 = validateParameter(valid_617885, JString, required = false,
                                 default = nil)
  if valid_617885 != nil:
    section.add "X-Amz-Security-Token", valid_617885
  var valid_617886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617886 = validateParameter(valid_617886, JString, required = false,
                                 default = nil)
  if valid_617886 != nil:
    section.add "X-Amz-Content-Sha256", valid_617886
  var valid_617887 = header.getOrDefault("X-Amz-Algorithm")
  valid_617887 = validateParameter(valid_617887, JString, required = false,
                                 default = nil)
  if valid_617887 != nil:
    section.add "X-Amz-Algorithm", valid_617887
  var valid_617888 = header.getOrDefault("X-Amz-Signature")
  valid_617888 = validateParameter(valid_617888, JString, required = false,
                                 default = nil)
  if valid_617888 != nil:
    section.add "X-Amz-Signature", valid_617888
  var valid_617889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617889 = validateParameter(valid_617889, JString, required = false,
                                 default = nil)
  if valid_617889 != nil:
    section.add "X-Amz-SignedHeaders", valid_617889
  var valid_617890 = header.getOrDefault("X-Amz-Credential")
  valid_617890 = validateParameter(valid_617890, JString, required = false,
                                 default = nil)
  if valid_617890 != nil:
    section.add "X-Amz-Credential", valid_617890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617892: Call_TagResource_617880; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ## 
  let valid = call_617892.validator(path, query, header, formData, body, _)
  let scheme = call_617892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617892.url(scheme.get, call_617892.host, call_617892.base,
                         call_617892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617892, url, valid, _)

proc call*(call_617893: Call_TagResource_617880; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to retrieve tags.
  ##   body: JObject (required)
  var path_617894 = newJObject()
  var body_617895 = newJObject()
  add(path_617894, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_617895 = body
  result = call_617893.call(path_617894, nil, nil, nil, body_617895)

var tagResource* = Call_TagResource_617880(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appconfig.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_617881,
                                        base: "/", url: url_TagResource_617882,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_617866 = ref object of OpenApiRestCall_616866
proc url_ListTagsForResource_617868(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_617867(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617869 = path.getOrDefault("ResourceArn")
  valid_617869 = validateParameter(valid_617869, JString, required = true,
                                 default = nil)
  if valid_617869 != nil:
    section.add "ResourceArn", valid_617869
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
  var valid_617870 = header.getOrDefault("X-Amz-Date")
  valid_617870 = validateParameter(valid_617870, JString, required = false,
                                 default = nil)
  if valid_617870 != nil:
    section.add "X-Amz-Date", valid_617870
  var valid_617871 = header.getOrDefault("X-Amz-Security-Token")
  valid_617871 = validateParameter(valid_617871, JString, required = false,
                                 default = nil)
  if valid_617871 != nil:
    section.add "X-Amz-Security-Token", valid_617871
  var valid_617872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617872 = validateParameter(valid_617872, JString, required = false,
                                 default = nil)
  if valid_617872 != nil:
    section.add "X-Amz-Content-Sha256", valid_617872
  var valid_617873 = header.getOrDefault("X-Amz-Algorithm")
  valid_617873 = validateParameter(valid_617873, JString, required = false,
                                 default = nil)
  if valid_617873 != nil:
    section.add "X-Amz-Algorithm", valid_617873
  var valid_617874 = header.getOrDefault("X-Amz-Signature")
  valid_617874 = validateParameter(valid_617874, JString, required = false,
                                 default = nil)
  if valid_617874 != nil:
    section.add "X-Amz-Signature", valid_617874
  var valid_617875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617875 = validateParameter(valid_617875, JString, required = false,
                                 default = nil)
  if valid_617875 != nil:
    section.add "X-Amz-SignedHeaders", valid_617875
  var valid_617876 = header.getOrDefault("X-Amz-Credential")
  valid_617876 = validateParameter(valid_617876, JString, required = false,
                                 default = nil)
  if valid_617876 != nil:
    section.add "X-Amz-Credential", valid_617876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617877: Call_ListTagsForResource_617866; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the list of key-value tags assigned to the resource.
  ## 
  let valid = call_617877.validator(path, query, header, formData, body, _)
  let scheme = call_617877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617877.url(scheme.get, call_617877.host, call_617877.base,
                         call_617877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617877, url, valid, _)

proc call*(call_617878: Call_ListTagsForResource_617866; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves the list of key-value tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The resource ARN.
  var path_617879 = newJObject()
  add(path_617879, "ResourceArn", newJString(ResourceArn))
  result = call_617878.call(path_617879, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_617866(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_617867, base: "/",
    url: url_ListTagsForResource_617868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617896 = ref object of OpenApiRestCall_616866
proc url_UntagResource_617898(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_617897(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
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
  var valid_617899 = path.getOrDefault("ResourceArn")
  valid_617899 = validateParameter(valid_617899, JString, required = true,
                                 default = nil)
  if valid_617899 != nil:
    section.add "ResourceArn", valid_617899
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_617900 = query.getOrDefault("tagKeys")
  valid_617900 = validateParameter(valid_617900, JArray, required = true, default = nil)
  if valid_617900 != nil:
    section.add "tagKeys", valid_617900
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
  var valid_617901 = header.getOrDefault("X-Amz-Date")
  valid_617901 = validateParameter(valid_617901, JString, required = false,
                                 default = nil)
  if valid_617901 != nil:
    section.add "X-Amz-Date", valid_617901
  var valid_617902 = header.getOrDefault("X-Amz-Security-Token")
  valid_617902 = validateParameter(valid_617902, JString, required = false,
                                 default = nil)
  if valid_617902 != nil:
    section.add "X-Amz-Security-Token", valid_617902
  var valid_617903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617903 = validateParameter(valid_617903, JString, required = false,
                                 default = nil)
  if valid_617903 != nil:
    section.add "X-Amz-Content-Sha256", valid_617903
  var valid_617904 = header.getOrDefault("X-Amz-Algorithm")
  valid_617904 = validateParameter(valid_617904, JString, required = false,
                                 default = nil)
  if valid_617904 != nil:
    section.add "X-Amz-Algorithm", valid_617904
  var valid_617905 = header.getOrDefault("X-Amz-Signature")
  valid_617905 = validateParameter(valid_617905, JString, required = false,
                                 default = nil)
  if valid_617905 != nil:
    section.add "X-Amz-Signature", valid_617905
  var valid_617906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617906 = validateParameter(valid_617906, JString, required = false,
                                 default = nil)
  if valid_617906 != nil:
    section.add "X-Amz-SignedHeaders", valid_617906
  var valid_617907 = header.getOrDefault("X-Amz-Credential")
  valid_617907 = validateParameter(valid_617907, JString, required = false,
                                 default = nil)
  if valid_617907 != nil:
    section.add "X-Amz-Credential", valid_617907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617908: Call_UntagResource_617896; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a tag key and value from an AppConfig resource.
  ## 
  let valid = call_617908.validator(path, query, header, formData, body, _)
  let scheme = call_617908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617908.url(scheme.get, call_617908.host, call_617908.base,
                         call_617908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617908, url, valid, _)

proc call*(call_617909: Call_UntagResource_617896; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Deletes a tag key and value from an AppConfig resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to remove tags.
  var path_617910 = newJObject()
  var query_617911 = newJObject()
  if tagKeys != nil:
    query_617911.add "tagKeys", tagKeys
  add(path_617910, "ResourceArn", newJString(ResourceArn))
  result = call_617909.call(path_617910, query_617911, nil, nil, nil)

var untagResource* = Call_UntagResource_617896(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_617897,
    base: "/", url: url_UntagResource_617898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidateConfiguration_617912 = ref object of OpenApiRestCall_616866
proc url_ValidateConfiguration_617914(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_ValidateConfiguration_617913(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Uses the validators in a configuration profile to validate a configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationProfileId: JString (required)
  ##                         : The configuration profile ID.
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationProfileId` field"
  var valid_617915 = path.getOrDefault("ConfigurationProfileId")
  valid_617915 = validateParameter(valid_617915, JString, required = true,
                                 default = nil)
  if valid_617915 != nil:
    section.add "ConfigurationProfileId", valid_617915
  var valid_617916 = path.getOrDefault("ApplicationId")
  valid_617916 = validateParameter(valid_617916, JString, required = true,
                                 default = nil)
  if valid_617916 != nil:
    section.add "ApplicationId", valid_617916
  result.add "path", section
  ## parameters in `query` object:
  ##   configuration_version: JString (required)
  ##                        : The version of the configuration to validate.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `configuration_version` field"
  var valid_617917 = query.getOrDefault("configuration_version")
  valid_617917 = validateParameter(valid_617917, JString, required = true,
                                 default = nil)
  if valid_617917 != nil:
    section.add "configuration_version", valid_617917
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
  var valid_617918 = header.getOrDefault("X-Amz-Date")
  valid_617918 = validateParameter(valid_617918, JString, required = false,
                                 default = nil)
  if valid_617918 != nil:
    section.add "X-Amz-Date", valid_617918
  var valid_617919 = header.getOrDefault("X-Amz-Security-Token")
  valid_617919 = validateParameter(valid_617919, JString, required = false,
                                 default = nil)
  if valid_617919 != nil:
    section.add "X-Amz-Security-Token", valid_617919
  var valid_617920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617920 = validateParameter(valid_617920, JString, required = false,
                                 default = nil)
  if valid_617920 != nil:
    section.add "X-Amz-Content-Sha256", valid_617920
  var valid_617921 = header.getOrDefault("X-Amz-Algorithm")
  valid_617921 = validateParameter(valid_617921, JString, required = false,
                                 default = nil)
  if valid_617921 != nil:
    section.add "X-Amz-Algorithm", valid_617921
  var valid_617922 = header.getOrDefault("X-Amz-Signature")
  valid_617922 = validateParameter(valid_617922, JString, required = false,
                                 default = nil)
  if valid_617922 != nil:
    section.add "X-Amz-Signature", valid_617922
  var valid_617923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617923 = validateParameter(valid_617923, JString, required = false,
                                 default = nil)
  if valid_617923 != nil:
    section.add "X-Amz-SignedHeaders", valid_617923
  var valid_617924 = header.getOrDefault("X-Amz-Credential")
  valid_617924 = validateParameter(valid_617924, JString, required = false,
                                 default = nil)
  if valid_617924 != nil:
    section.add "X-Amz-Credential", valid_617924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617925: Call_ValidateConfiguration_617912; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Uses the validators in a configuration profile to validate a configuration.
  ## 
  let valid = call_617925.validator(path, query, header, formData, body, _)
  let scheme = call_617925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617925.url(scheme.get, call_617925.host, call_617925.base,
                         call_617925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617925, url, valid, _)

proc call*(call_617926: Call_ValidateConfiguration_617912;
          ConfigurationProfileId: string; configurationVersion: string;
          ApplicationId: string): Recallable =
  ## validateConfiguration
  ## Uses the validators in a configuration profile to validate a configuration.
  ##   ConfigurationProfileId: string (required)
  ##                         : The configuration profile ID.
  ##   configurationVersion: string (required)
  ##                       : The version of the configuration to validate.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  var path_617927 = newJObject()
  var query_617928 = newJObject()
  add(path_617927, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(query_617928, "configuration_version", newJString(configurationVersion))
  add(path_617927, "ApplicationId", newJString(ApplicationId))
  result = call_617926.call(path_617927, query_617928, nil, nil, nil)

var validateConfiguration* = Call_ValidateConfiguration_617912(
    name: "validateConfiguration", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}/validators#configuration_version",
    validator: validate_ValidateConfiguration_617913, base: "/",
    url: url_ValidateConfiguration_617914, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
