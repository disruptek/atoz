
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "appconfig.ap-northeast-1.amazonaws.com", "ap-southeast-1": "appconfig.ap-southeast-1.amazonaws.com",
                           "us-west-2": "appconfig.us-west-2.amazonaws.com",
                           "eu-west-2": "appconfig.eu-west-2.amazonaws.com", "ap-northeast-3": "appconfig.ap-northeast-3.amazonaws.com", "eu-central-1": "appconfig.eu-central-1.amazonaws.com",
                           "us-east-2": "appconfig.us-east-2.amazonaws.com",
                           "us-east-1": "appconfig.us-east-1.amazonaws.com", "cn-northwest-1": "appconfig.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "appconfig.ap-south-1.amazonaws.com",
                           "eu-north-1": "appconfig.eu-north-1.amazonaws.com", "ap-northeast-2": "appconfig.ap-northeast-2.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApplication_613255 = ref object of OpenApiRestCall_612658
proc url_CreateApplication_613257(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_613256(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
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
  var valid_613258 = header.getOrDefault("X-Amz-Signature")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Signature", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Content-Sha256", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Date")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Date", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Credential")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Credential", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Security-Token")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Security-Token", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Algorithm")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Algorithm", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-SignedHeaders", valid_613264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613266: Call_CreateApplication_613255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ## 
  let valid = call_613266.validator(path, query, header, formData, body)
  let scheme = call_613266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613266.url(scheme.get, call_613266.host, call_613266.base,
                         call_613266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613266, url, valid)

proc call*(call_613267: Call_CreateApplication_613255; body: JsonNode): Recallable =
  ## createApplication
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ##   body: JObject (required)
  var body_613268 = newJObject()
  if body != nil:
    body_613268 = body
  result = call_613267.call(nil, nil, nil, nil, body_613268)

var createApplication* = Call_CreateApplication_613255(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_613256, base: "/",
    url: url_CreateApplication_613257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_612996 = ref object of OpenApiRestCall_612658
proc url_ListApplications_612998(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_612997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## List all applications in your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  section = newJObject()
  var valid_613110 = query.getOrDefault("MaxResults")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "MaxResults", valid_613110
  var valid_613111 = query.getOrDefault("NextToken")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "NextToken", valid_613111
  var valid_613112 = query.getOrDefault("next_token")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "next_token", valid_613112
  var valid_613113 = query.getOrDefault("max_results")
  valid_613113 = validateParameter(valid_613113, JInt, required = false, default = nil)
  if valid_613113 != nil:
    section.add "max_results", valid_613113
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
  var valid_613114 = header.getOrDefault("X-Amz-Signature")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Signature", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Content-Sha256", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Date")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Date", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Credential")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Credential", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Security-Token")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Security-Token", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Algorithm")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Algorithm", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-SignedHeaders", valid_613120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613143: Call_ListApplications_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all applications in your AWS account.
  ## 
  let valid = call_613143.validator(path, query, header, formData, body)
  let scheme = call_613143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613143.url(scheme.get, call_613143.host, call_613143.base,
                         call_613143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613143, url, valid)

proc call*(call_613214: Call_ListApplications_612996; MaxResults: string = "";
          NextToken: string = ""; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listApplications
  ## List all applications in your AWS account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  var query_613215 = newJObject()
  add(query_613215, "MaxResults", newJString(MaxResults))
  add(query_613215, "NextToken", newJString(NextToken))
  add(query_613215, "next_token", newJString(nextToken))
  add(query_613215, "max_results", newJInt(maxResults))
  result = call_613214.call(nil, query_613215, nil, nil, nil)

var listApplications* = Call_ListApplications_612996(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_612997, base: "/",
    url: url_ListApplications_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationProfile_613302 = ref object of OpenApiRestCall_612658
proc url_CreateConfigurationProfile_613304(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationProfile_613303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613305 = path.getOrDefault("ApplicationId")
  valid_613305 = validateParameter(valid_613305, JString, required = true,
                                 default = nil)
  if valid_613305 != nil:
    section.add "ApplicationId", valid_613305
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
  var valid_613306 = header.getOrDefault("X-Amz-Signature")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Signature", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Content-Sha256", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Date")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Date", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Credential")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Credential", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Security-Token")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Security-Token", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Algorithm")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Algorithm", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-SignedHeaders", valid_613312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613314: Call_CreateConfigurationProfile_613302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ## 
  let valid = call_613314.validator(path, query, header, formData, body)
  let scheme = call_613314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613314.url(scheme.get, call_613314.host, call_613314.base,
                         call_613314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613314, url, valid)

proc call*(call_613315: Call_CreateConfigurationProfile_613302;
          ApplicationId: string; body: JsonNode): Recallable =
  ## createConfigurationProfile
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_613316 = newJObject()
  var body_613317 = newJObject()
  add(path_613316, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_613317 = body
  result = call_613315.call(path_613316, nil, nil, nil, body_613317)

var createConfigurationProfile* = Call_CreateConfigurationProfile_613302(
    name: "createConfigurationProfile", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_CreateConfigurationProfile_613303, base: "/",
    url: url_CreateConfigurationProfile_613304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationProfiles_613269 = ref object of OpenApiRestCall_612658
proc url_ListConfigurationProfiles_613271(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListConfigurationProfiles_613270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613286 = path.getOrDefault("ApplicationId")
  valid_613286 = validateParameter(valid_613286, JString, required = true,
                                 default = nil)
  if valid_613286 != nil:
    section.add "ApplicationId", valid_613286
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  section = newJObject()
  var valid_613287 = query.getOrDefault("MaxResults")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "MaxResults", valid_613287
  var valid_613288 = query.getOrDefault("NextToken")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "NextToken", valid_613288
  var valid_613289 = query.getOrDefault("next_token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "next_token", valid_613289
  var valid_613290 = query.getOrDefault("max_results")
  valid_613290 = validateParameter(valid_613290, JInt, required = false, default = nil)
  if valid_613290 != nil:
    section.add "max_results", valid_613290
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
  var valid_613291 = header.getOrDefault("X-Amz-Signature")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Signature", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Content-Sha256", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Date")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Date", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Credential")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Credential", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Security-Token")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Security-Token", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Algorithm")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Algorithm", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-SignedHeaders", valid_613297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613298: Call_ListConfigurationProfiles_613269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the configuration profiles for an application.
  ## 
  let valid = call_613298.validator(path, query, header, formData, body)
  let scheme = call_613298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613298.url(scheme.get, call_613298.host, call_613298.base,
                         call_613298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613298, url, valid)

proc call*(call_613299: Call_ListConfigurationProfiles_613269;
          ApplicationId: string; MaxResults: string = ""; NextToken: string = "";
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listConfigurationProfiles
  ## Lists the configuration profiles for an application.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  var path_613300 = newJObject()
  var query_613301 = newJObject()
  add(query_613301, "MaxResults", newJString(MaxResults))
  add(query_613301, "NextToken", newJString(NextToken))
  add(query_613301, "next_token", newJString(nextToken))
  add(path_613300, "ApplicationId", newJString(ApplicationId))
  add(query_613301, "max_results", newJInt(maxResults))
  result = call_613299.call(path_613300, query_613301, nil, nil, nil)

var listConfigurationProfiles* = Call_ListConfigurationProfiles_613269(
    name: "listConfigurationProfiles", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_ListConfigurationProfiles_613270, base: "/",
    url: url_ListConfigurationProfiles_613271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentStrategy_613335 = ref object of OpenApiRestCall_612658
proc url_CreateDeploymentStrategy_613337(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentStrategy_613336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
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
  var valid_613338 = header.getOrDefault("X-Amz-Signature")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Signature", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Content-Sha256", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Date")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Date", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Credential")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Credential", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Security-Token")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Security-Token", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Algorithm")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Algorithm", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-SignedHeaders", valid_613344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613346: Call_CreateDeploymentStrategy_613335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_613346.validator(path, query, header, formData, body)
  let scheme = call_613346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613346.url(scheme.get, call_613346.host, call_613346.base,
                         call_613346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613346, url, valid)

proc call*(call_613347: Call_CreateDeploymentStrategy_613335; body: JsonNode): Recallable =
  ## createDeploymentStrategy
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   body: JObject (required)
  var body_613348 = newJObject()
  if body != nil:
    body_613348 = body
  result = call_613347.call(nil, nil, nil, nil, body_613348)

var createDeploymentStrategy* = Call_CreateDeploymentStrategy_613335(
    name: "createDeploymentStrategy", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_CreateDeploymentStrategy_613336, base: "/",
    url: url_CreateDeploymentStrategy_613337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentStrategies_613318 = ref object of OpenApiRestCall_612658
proc url_ListDeploymentStrategies_613320(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentStrategies_613319(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List deployment strategies.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  section = newJObject()
  var valid_613321 = query.getOrDefault("MaxResults")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "MaxResults", valid_613321
  var valid_613322 = query.getOrDefault("NextToken")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "NextToken", valid_613322
  var valid_613323 = query.getOrDefault("next_token")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "next_token", valid_613323
  var valid_613324 = query.getOrDefault("max_results")
  valid_613324 = validateParameter(valid_613324, JInt, required = false, default = nil)
  if valid_613324 != nil:
    section.add "max_results", valid_613324
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
  var valid_613325 = header.getOrDefault("X-Amz-Signature")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Signature", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Content-Sha256", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Date")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Date", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Credential")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Credential", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Security-Token")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Security-Token", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Algorithm")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Algorithm", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-SignedHeaders", valid_613331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613332: Call_ListDeploymentStrategies_613318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List deployment strategies.
  ## 
  let valid = call_613332.validator(path, query, header, formData, body)
  let scheme = call_613332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613332.url(scheme.get, call_613332.host, call_613332.base,
                         call_613332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613332, url, valid)

proc call*(call_613333: Call_ListDeploymentStrategies_613318;
          MaxResults: string = ""; NextToken: string = ""; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDeploymentStrategies
  ## List deployment strategies.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  var query_613334 = newJObject()
  add(query_613334, "MaxResults", newJString(MaxResults))
  add(query_613334, "NextToken", newJString(NextToken))
  add(query_613334, "next_token", newJString(nextToken))
  add(query_613334, "max_results", newJInt(maxResults))
  result = call_613333.call(nil, query_613334, nil, nil, nil)

var listDeploymentStrategies* = Call_ListDeploymentStrategies_613318(
    name: "listDeploymentStrategies", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_ListDeploymentStrategies_613319, base: "/",
    url: url_ListDeploymentStrategies_613320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironment_613368 = ref object of OpenApiRestCall_612658
proc url_CreateEnvironment_613370(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateEnvironment_613369(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_613371 = path.getOrDefault("ApplicationId")
  valid_613371 = validateParameter(valid_613371, JString, required = true,
                                 default = nil)
  if valid_613371 != nil:
    section.add "ApplicationId", valid_613371
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
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613380: Call_CreateEnvironment_613368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ## 
  let valid = call_613380.validator(path, query, header, formData, body)
  let scheme = call_613380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613380.url(scheme.get, call_613380.host, call_613380.base,
                         call_613380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613380, url, valid)

proc call*(call_613381: Call_CreateEnvironment_613368; ApplicationId: string;
          body: JsonNode): Recallable =
  ## createEnvironment
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_613382 = newJObject()
  var body_613383 = newJObject()
  add(path_613382, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_613383 = body
  result = call_613381.call(path_613382, nil, nil, nil, body_613383)

var createEnvironment* = Call_CreateEnvironment_613368(name: "createEnvironment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_CreateEnvironment_613369, base: "/",
    url: url_CreateEnvironment_613370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_613349 = ref object of OpenApiRestCall_612658
proc url_ListEnvironments_613351(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListEnvironments_613350(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_613352 = path.getOrDefault("ApplicationId")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "ApplicationId", valid_613352
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  section = newJObject()
  var valid_613353 = query.getOrDefault("MaxResults")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "MaxResults", valid_613353
  var valid_613354 = query.getOrDefault("NextToken")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "NextToken", valid_613354
  var valid_613355 = query.getOrDefault("next_token")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "next_token", valid_613355
  var valid_613356 = query.getOrDefault("max_results")
  valid_613356 = validateParameter(valid_613356, JInt, required = false, default = nil)
  if valid_613356 != nil:
    section.add "max_results", valid_613356
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
  var valid_613357 = header.getOrDefault("X-Amz-Signature")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Signature", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Content-Sha256", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Date")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Date", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Credential")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Credential", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Security-Token")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Security-Token", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Algorithm")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Algorithm", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-SignedHeaders", valid_613363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613364: Call_ListEnvironments_613349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the environments for an application.
  ## 
  let valid = call_613364.validator(path, query, header, formData, body)
  let scheme = call_613364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613364.url(scheme.get, call_613364.host, call_613364.base,
                         call_613364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613364, url, valid)

proc call*(call_613365: Call_ListEnvironments_613349; ApplicationId: string;
          MaxResults: string = ""; NextToken: string = ""; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listEnvironments
  ## List the environments for an application.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  var path_613366 = newJObject()
  var query_613367 = newJObject()
  add(query_613367, "MaxResults", newJString(MaxResults))
  add(query_613367, "NextToken", newJString(NextToken))
  add(query_613367, "next_token", newJString(nextToken))
  add(path_613366, "ApplicationId", newJString(ApplicationId))
  add(query_613367, "max_results", newJInt(maxResults))
  result = call_613365.call(path_613366, query_613367, nil, nil, nil)

var listEnvironments* = Call_ListEnvironments_613349(name: "listEnvironments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_ListEnvironments_613350, base: "/",
    url: url_ListEnvironments_613351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_613384 = ref object of OpenApiRestCall_612658
proc url_GetApplication_613386(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetApplication_613385(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_613387 = path.getOrDefault("ApplicationId")
  valid_613387 = validateParameter(valid_613387, JString, required = true,
                                 default = nil)
  if valid_613387 != nil:
    section.add "ApplicationId", valid_613387
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
  var valid_613388 = header.getOrDefault("X-Amz-Signature")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Signature", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Content-Sha256", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Date")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Date", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Credential")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Credential", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Security-Token")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Security-Token", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Algorithm")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Algorithm", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-SignedHeaders", valid_613394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_GetApplication_613384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_GetApplication_613384; ApplicationId: string): Recallable =
  ## getApplication
  ## Retrieve information about an application.
  ##   ApplicationId: string (required)
  ##                : The ID of the application you want to get.
  var path_613397 = newJObject()
  add(path_613397, "ApplicationId", newJString(ApplicationId))
  result = call_613396.call(path_613397, nil, nil, nil, nil)

var getApplication* = Call_GetApplication_613384(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_GetApplication_613385,
    base: "/", url: url_GetApplication_613386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_613412 = ref object of OpenApiRestCall_612658
proc url_UpdateApplication_613414(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateApplication_613413(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_613415 = path.getOrDefault("ApplicationId")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "ApplicationId", valid_613415
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
  var valid_613416 = header.getOrDefault("X-Amz-Signature")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Signature", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Content-Sha256", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Date")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Date", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Credential")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Credential", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Security-Token")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Security-Token", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Algorithm")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Algorithm", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-SignedHeaders", valid_613422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613424: Call_UpdateApplication_613412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_613424.validator(path, query, header, formData, body)
  let scheme = call_613424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613424.url(scheme.get, call_613424.host, call_613424.base,
                         call_613424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613424, url, valid)

proc call*(call_613425: Call_UpdateApplication_613412; ApplicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates an application.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_613426 = newJObject()
  var body_613427 = newJObject()
  add(path_613426, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_613427 = body
  result = call_613425.call(path_613426, nil, nil, nil, body_613427)

var updateApplication* = Call_UpdateApplication_613412(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_UpdateApplication_613413,
    base: "/", url: url_UpdateApplication_613414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_613398 = ref object of OpenApiRestCall_612658
proc url_DeleteApplication_613400(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteApplication_613399(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_613401 = path.getOrDefault("ApplicationId")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = nil)
  if valid_613401 != nil:
    section.add "ApplicationId", valid_613401
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
  var valid_613402 = header.getOrDefault("X-Amz-Signature")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Signature", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Content-Sha256", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Date")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Date", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Credential")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Credential", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Security-Token")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Security-Token", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Algorithm")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Algorithm", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-SignedHeaders", valid_613408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613409: Call_DeleteApplication_613398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ## 
  let valid = call_613409.validator(path, query, header, formData, body)
  let scheme = call_613409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613409.url(scheme.get, call_613409.host, call_613409.base,
                         call_613409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613409, url, valid)

proc call*(call_613410: Call_DeleteApplication_613398; ApplicationId: string): Recallable =
  ## deleteApplication
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The ID of the application to delete.
  var path_613411 = newJObject()
  add(path_613411, "ApplicationId", newJString(ApplicationId))
  result = call_613410.call(path_613411, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_613398(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_DeleteApplication_613399,
    base: "/", url: url_DeleteApplication_613400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationProfile_613428 = ref object of OpenApiRestCall_612658
proc url_GetConfigurationProfile_613430(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationProfile_613429(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve information about a configuration profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The ID of the application that includes the configuration profile you want to get.
  ##   ConfigurationProfileId: JString (required)
  ##                         : The ID of the configuration profile you want to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_613431 = path.getOrDefault("ApplicationId")
  valid_613431 = validateParameter(valid_613431, JString, required = true,
                                 default = nil)
  if valid_613431 != nil:
    section.add "ApplicationId", valid_613431
  var valid_613432 = path.getOrDefault("ConfigurationProfileId")
  valid_613432 = validateParameter(valid_613432, JString, required = true,
                                 default = nil)
  if valid_613432 != nil:
    section.add "ConfigurationProfileId", valid_613432
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
  var valid_613433 = header.getOrDefault("X-Amz-Signature")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Signature", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Content-Sha256", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Date")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Date", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Credential")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Credential", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Security-Token")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Security-Token", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Algorithm")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Algorithm", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-SignedHeaders", valid_613439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613440: Call_GetConfigurationProfile_613428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration profile.
  ## 
  let valid = call_613440.validator(path, query, header, formData, body)
  let scheme = call_613440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613440.url(scheme.get, call_613440.host, call_613440.base,
                         call_613440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613440, url, valid)

proc call*(call_613441: Call_GetConfigurationProfile_613428; ApplicationId: string;
          ConfigurationProfileId: string): Recallable =
  ## getConfigurationProfile
  ## Retrieve information about a configuration profile.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the configuration profile you want to get.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to get.
  var path_613442 = newJObject()
  add(path_613442, "ApplicationId", newJString(ApplicationId))
  add(path_613442, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_613441.call(path_613442, nil, nil, nil, nil)

var getConfigurationProfile* = Call_GetConfigurationProfile_613428(
    name: "getConfigurationProfile", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_GetConfigurationProfile_613429, base: "/",
    url: url_GetConfigurationProfile_613430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationProfile_613458 = ref object of OpenApiRestCall_612658
proc url_UpdateConfigurationProfile_613460(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfigurationProfile_613459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a configuration profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  ##   ConfigurationProfileId: JString (required)
  ##                         : The ID of the configuration profile.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_613461 = path.getOrDefault("ApplicationId")
  valid_613461 = validateParameter(valid_613461, JString, required = true,
                                 default = nil)
  if valid_613461 != nil:
    section.add "ApplicationId", valid_613461
  var valid_613462 = path.getOrDefault("ConfigurationProfileId")
  valid_613462 = validateParameter(valid_613462, JString, required = true,
                                 default = nil)
  if valid_613462 != nil:
    section.add "ConfigurationProfileId", valid_613462
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
  var valid_613463 = header.getOrDefault("X-Amz-Signature")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Signature", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Content-Sha256", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Date")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Date", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Credential")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Credential", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Security-Token")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Security-Token", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Algorithm")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Algorithm", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-SignedHeaders", valid_613469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613471: Call_UpdateConfigurationProfile_613458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a configuration profile.
  ## 
  let valid = call_613471.validator(path, query, header, formData, body)
  let scheme = call_613471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613471.url(scheme.get, call_613471.host, call_613471.base,
                         call_613471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613471, url, valid)

proc call*(call_613472: Call_UpdateConfigurationProfile_613458;
          ApplicationId: string; body: JsonNode; ConfigurationProfileId: string): Recallable =
  ## updateConfigurationProfile
  ## Updates a configuration profile.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile.
  var path_613473 = newJObject()
  var body_613474 = newJObject()
  add(path_613473, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_613474 = body
  add(path_613473, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_613472.call(path_613473, nil, nil, nil, body_613474)

var updateConfigurationProfile* = Call_UpdateConfigurationProfile_613458(
    name: "updateConfigurationProfile", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_UpdateConfigurationProfile_613459, base: "/",
    url: url_UpdateConfigurationProfile_613460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationProfile_613443 = ref object of OpenApiRestCall_612658
proc url_DeleteConfigurationProfile_613445(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationProfile_613444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The application ID that includes the configuration profile you want to delete.
  ##   ConfigurationProfileId: JString (required)
  ##                         : The ID of the configuration profile you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_613446 = path.getOrDefault("ApplicationId")
  valid_613446 = validateParameter(valid_613446, JString, required = true,
                                 default = nil)
  if valid_613446 != nil:
    section.add "ApplicationId", valid_613446
  var valid_613447 = path.getOrDefault("ConfigurationProfileId")
  valid_613447 = validateParameter(valid_613447, JString, required = true,
                                 default = nil)
  if valid_613447 != nil:
    section.add "ConfigurationProfileId", valid_613447
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
  var valid_613448 = header.getOrDefault("X-Amz-Signature")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Signature", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Content-Sha256", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Date")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Date", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Credential")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Credential", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Security-Token")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Security-Token", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Algorithm")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Algorithm", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-SignedHeaders", valid_613454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613455: Call_DeleteConfigurationProfile_613443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ## 
  let valid = call_613455.validator(path, query, header, formData, body)
  let scheme = call_613455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613455.url(scheme.get, call_613455.host, call_613455.base,
                         call_613455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613455, url, valid)

proc call*(call_613456: Call_DeleteConfigurationProfile_613443;
          ApplicationId: string; ConfigurationProfileId: string): Recallable =
  ## deleteConfigurationProfile
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the configuration profile you want to delete.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to delete.
  var path_613457 = newJObject()
  add(path_613457, "ApplicationId", newJString(ApplicationId))
  add(path_613457, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_613456.call(path_613457, nil, nil, nil, nil)

var deleteConfigurationProfile* = Call_DeleteConfigurationProfile_613443(
    name: "deleteConfigurationProfile", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_DeleteConfigurationProfile_613444, base: "/",
    url: url_DeleteConfigurationProfile_613445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentStrategy_613475 = ref object of OpenApiRestCall_612658
proc url_DeleteDeploymentStrategy_613477(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDeploymentStrategy_613476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The ID of the deployment strategy you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_613478 = path.getOrDefault("DeploymentStrategyId")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = nil)
  if valid_613478 != nil:
    section.add "DeploymentStrategyId", valid_613478
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
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613486: Call_DeleteDeploymentStrategy_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  let valid = call_613486.validator(path, query, header, formData, body)
  let scheme = call_613486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613486.url(scheme.get, call_613486.host, call_613486.base,
                         call_613486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613486, url, valid)

proc call*(call_613487: Call_DeleteDeploymentStrategy_613475;
          DeploymentStrategyId: string): Recallable =
  ## deleteDeploymentStrategy
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy you want to delete.
  var path_613488 = newJObject()
  add(path_613488, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_613487.call(path_613488, nil, nil, nil, nil)

var deleteDeploymentStrategy* = Call_DeleteDeploymentStrategy_613475(
    name: "deleteDeploymentStrategy", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com",
    route: "/deployementstrategies/{DeploymentStrategyId}",
    validator: validate_DeleteDeploymentStrategy_613476, base: "/",
    url: url_DeleteDeploymentStrategy_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnvironment_613489 = ref object of OpenApiRestCall_612658
proc url_GetEnvironment_613491(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEnvironment_613490(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EnvironmentId: JString (required)
  ##                : The ID of the environment you wnat to get.
  ##   ApplicationId: JString (required)
  ##                : The ID of the application that includes the environment you want to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EnvironmentId` field"
  var valid_613492 = path.getOrDefault("EnvironmentId")
  valid_613492 = validateParameter(valid_613492, JString, required = true,
                                 default = nil)
  if valid_613492 != nil:
    section.add "EnvironmentId", valid_613492
  var valid_613493 = path.getOrDefault("ApplicationId")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = nil)
  if valid_613493 != nil:
    section.add "ApplicationId", valid_613493
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
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613501: Call_GetEnvironment_613489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ## 
  let valid = call_613501.validator(path, query, header, formData, body)
  let scheme = call_613501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613501.url(scheme.get, call_613501.host, call_613501.base,
                         call_613501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613501, url, valid)

proc call*(call_613502: Call_GetEnvironment_613489; EnvironmentId: string;
          ApplicationId: string): Recallable =
  ## getEnvironment
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you wnat to get.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the environment you want to get.
  var path_613503 = newJObject()
  add(path_613503, "EnvironmentId", newJString(EnvironmentId))
  add(path_613503, "ApplicationId", newJString(ApplicationId))
  result = call_613502.call(path_613503, nil, nil, nil, nil)

var getEnvironment* = Call_GetEnvironment_613489(name: "getEnvironment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_GetEnvironment_613490, base: "/", url: url_GetEnvironment_613491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_613519 = ref object of OpenApiRestCall_612658
proc url_UpdateEnvironment_613521(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEnvironment_613520(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates an environment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EnvironmentId` field"
  var valid_613522 = path.getOrDefault("EnvironmentId")
  valid_613522 = validateParameter(valid_613522, JString, required = true,
                                 default = nil)
  if valid_613522 != nil:
    section.add "EnvironmentId", valid_613522
  var valid_613523 = path.getOrDefault("ApplicationId")
  valid_613523 = validateParameter(valid_613523, JString, required = true,
                                 default = nil)
  if valid_613523 != nil:
    section.add "ApplicationId", valid_613523
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
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_UpdateEnvironment_613519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an environment.
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_UpdateEnvironment_613519; EnvironmentId: string;
          ApplicationId: string; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Updates an environment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_613534 = newJObject()
  var body_613535 = newJObject()
  add(path_613534, "EnvironmentId", newJString(EnvironmentId))
  add(path_613534, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_613535 = body
  result = call_613533.call(path_613534, nil, nil, nil, body_613535)

var updateEnvironment* = Call_UpdateEnvironment_613519(name: "updateEnvironment",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_UpdateEnvironment_613520, base: "/",
    url: url_UpdateEnvironment_613521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_613504 = ref object of OpenApiRestCall_612658
proc url_DeleteEnvironment_613506(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEnvironment_613505(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EnvironmentId: JString (required)
  ##                : The ID of the environment you want to delete.
  ##   ApplicationId: JString (required)
  ##                : The application ID that includes the environment you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EnvironmentId` field"
  var valid_613507 = path.getOrDefault("EnvironmentId")
  valid_613507 = validateParameter(valid_613507, JString, required = true,
                                 default = nil)
  if valid_613507 != nil:
    section.add "EnvironmentId", valid_613507
  var valid_613508 = path.getOrDefault("ApplicationId")
  valid_613508 = validateParameter(valid_613508, JString, required = true,
                                 default = nil)
  if valid_613508 != nil:
    section.add "ApplicationId", valid_613508
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
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613516: Call_DeleteEnvironment_613504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ## 
  let valid = call_613516.validator(path, query, header, formData, body)
  let scheme = call_613516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613516.url(scheme.get, call_613516.host, call_613516.base,
                         call_613516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613516, url, valid)

proc call*(call_613517: Call_DeleteEnvironment_613504; EnvironmentId: string;
          ApplicationId: string): Recallable =
  ## deleteEnvironment
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you want to delete.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the environment you want to delete.
  var path_613518 = newJObject()
  add(path_613518, "EnvironmentId", newJString(EnvironmentId))
  add(path_613518, "ApplicationId", newJString(ApplicationId))
  result = call_613517.call(path_613518, nil, nil, nil, nil)

var deleteEnvironment* = Call_DeleteEnvironment_613504(name: "deleteEnvironment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_DeleteEnvironment_613505, base: "/",
    url: url_DeleteEnvironment_613506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfiguration_613536 = ref object of OpenApiRestCall_612658
proc url_GetConfiguration_613538(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfiguration_613537(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieve information about a configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Environment: JString (required)
  ##              : The environment to get.
  ##   Application: JString (required)
  ##              : The application to get.
  ##   Configuration: JString (required)
  ##                : The configuration to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `Environment` field"
  var valid_613539 = path.getOrDefault("Environment")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = nil)
  if valid_613539 != nil:
    section.add "Environment", valid_613539
  var valid_613540 = path.getOrDefault("Application")
  valid_613540 = validateParameter(valid_613540, JString, required = true,
                                 default = nil)
  if valid_613540 != nil:
    section.add "Application", valid_613540
  var valid_613541 = path.getOrDefault("Configuration")
  valid_613541 = validateParameter(valid_613541, JString, required = true,
                                 default = nil)
  if valid_613541 != nil:
    section.add "Configuration", valid_613541
  result.add "path", section
  ## parameters in `query` object:
  ##   client_id: JString (required)
  ##            : A unique ID to identify the client for the configuration. This ID enables AppConfig to deploy the configuration in intervals, as defined in the deployment strategy.
  ##   client_configuration_version: JString
  ##                               : The configuration version returned in the most recent GetConfiguration response.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `client_id` field"
  var valid_613542 = query.getOrDefault("client_id")
  valid_613542 = validateParameter(valid_613542, JString, required = true,
                                 default = nil)
  if valid_613542 != nil:
    section.add "client_id", valid_613542
  var valid_613543 = query.getOrDefault("client_configuration_version")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "client_configuration_version", valid_613543
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
  var valid_613544 = header.getOrDefault("X-Amz-Signature")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Signature", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Content-Sha256", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Date")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Date", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Credential")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Credential", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Security-Token")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Security-Token", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Algorithm")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Algorithm", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-SignedHeaders", valid_613550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613551: Call_GetConfiguration_613536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration.
  ## 
  let valid = call_613551.validator(path, query, header, formData, body)
  let scheme = call_613551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613551.url(scheme.get, call_613551.host, call_613551.base,
                         call_613551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613551, url, valid)

proc call*(call_613552: Call_GetConfiguration_613536; Environment: string;
          Application: string; Configuration: string; clientId: string;
          clientConfigurationVersion: string = ""): Recallable =
  ## getConfiguration
  ## Retrieve information about a configuration.
  ##   Environment: string (required)
  ##              : The environment to get.
  ##   Application: string (required)
  ##              : The application to get.
  ##   Configuration: string (required)
  ##                : The configuration to get.
  ##   clientId: string (required)
  ##           : A unique ID to identify the client for the configuration. This ID enables AppConfig to deploy the configuration in intervals, as defined in the deployment strategy.
  ##   clientConfigurationVersion: string
  ##                             : The configuration version returned in the most recent GetConfiguration response.
  var path_613553 = newJObject()
  var query_613554 = newJObject()
  add(path_613553, "Environment", newJString(Environment))
  add(path_613553, "Application", newJString(Application))
  add(path_613553, "Configuration", newJString(Configuration))
  add(query_613554, "client_id", newJString(clientId))
  add(query_613554, "client_configuration_version",
      newJString(clientConfigurationVersion))
  result = call_613552.call(path_613553, query_613554, nil, nil, nil)

var getConfiguration* = Call_GetConfiguration_613536(name: "getConfiguration",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{Application}/environments/{Environment}/configurations/{Configuration}#client_id",
    validator: validate_GetConfiguration_613537, base: "/",
    url: url_GetConfiguration_613538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_613555 = ref object of OpenApiRestCall_612658
proc url_GetDeployment_613557(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeployment_613556(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve information about a configuration deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentNumber: JInt (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: JString (required)
  ##                : The ID of the environment that includes the deployment you want to get. 
  ##   ApplicationId: JString (required)
  ##                : The ID of the application that includes the deployment you want to get. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeploymentNumber` field"
  var valid_613558 = path.getOrDefault("DeploymentNumber")
  valid_613558 = validateParameter(valid_613558, JInt, required = true, default = nil)
  if valid_613558 != nil:
    section.add "DeploymentNumber", valid_613558
  var valid_613559 = path.getOrDefault("EnvironmentId")
  valid_613559 = validateParameter(valid_613559, JString, required = true,
                                 default = nil)
  if valid_613559 != nil:
    section.add "EnvironmentId", valid_613559
  var valid_613560 = path.getOrDefault("ApplicationId")
  valid_613560 = validateParameter(valid_613560, JString, required = true,
                                 default = nil)
  if valid_613560 != nil:
    section.add "ApplicationId", valid_613560
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
  var valid_613561 = header.getOrDefault("X-Amz-Signature")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Signature", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Content-Sha256", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Date")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Date", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Credential")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Credential", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Security-Token")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Security-Token", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Algorithm")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Algorithm", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-SignedHeaders", valid_613567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613568: Call_GetDeployment_613555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration deployment.
  ## 
  let valid = call_613568.validator(path, query, header, formData, body)
  let scheme = call_613568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613568.url(scheme.get, call_613568.host, call_613568.base,
                         call_613568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613568, url, valid)

proc call*(call_613569: Call_GetDeployment_613555; DeploymentNumber: int;
          EnvironmentId: string; ApplicationId: string): Recallable =
  ## getDeployment
  ## Retrieve information about a configuration deployment.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment that includes the deployment you want to get. 
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the deployment you want to get. 
  var path_613570 = newJObject()
  add(path_613570, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_613570, "EnvironmentId", newJString(EnvironmentId))
  add(path_613570, "ApplicationId", newJString(ApplicationId))
  result = call_613569.call(path_613570, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_613555(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_GetDeployment_613556, base: "/", url: url_GetDeployment_613557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_613571 = ref object of OpenApiRestCall_612658
proc url_StopDeployment_613573(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopDeployment_613572(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentNumber: JInt (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeploymentNumber` field"
  var valid_613574 = path.getOrDefault("DeploymentNumber")
  valid_613574 = validateParameter(valid_613574, JInt, required = true, default = nil)
  if valid_613574 != nil:
    section.add "DeploymentNumber", valid_613574
  var valid_613575 = path.getOrDefault("EnvironmentId")
  valid_613575 = validateParameter(valid_613575, JString, required = true,
                                 default = nil)
  if valid_613575 != nil:
    section.add "EnvironmentId", valid_613575
  var valid_613576 = path.getOrDefault("ApplicationId")
  valid_613576 = validateParameter(valid_613576, JString, required = true,
                                 default = nil)
  if valid_613576 != nil:
    section.add "ApplicationId", valid_613576
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
  var valid_613577 = header.getOrDefault("X-Amz-Signature")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Signature", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Content-Sha256", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Date")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Date", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Credential")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Credential", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Security-Token")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Security-Token", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Algorithm")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Algorithm", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-SignedHeaders", valid_613583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613584: Call_StopDeployment_613571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ## 
  let valid = call_613584.validator(path, query, header, formData, body)
  let scheme = call_613584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613584.url(scheme.get, call_613584.host, call_613584.base,
                         call_613584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613584, url, valid)

proc call*(call_613585: Call_StopDeployment_613571; DeploymentNumber: int;
          EnvironmentId: string; ApplicationId: string): Recallable =
  ## stopDeployment
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  var path_613586 = newJObject()
  add(path_613586, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_613586, "EnvironmentId", newJString(EnvironmentId))
  add(path_613586, "ApplicationId", newJString(ApplicationId))
  result = call_613585.call(path_613586, nil, nil, nil, nil)

var stopDeployment* = Call_StopDeployment_613571(name: "stopDeployment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_StopDeployment_613572, base: "/", url: url_StopDeployment_613573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStrategy_613587 = ref object of OpenApiRestCall_612658
proc url_GetDeploymentStrategy_613589(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeploymentStrategy_613588(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The ID of the deployment strategy to get.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_613590 = path.getOrDefault("DeploymentStrategyId")
  valid_613590 = validateParameter(valid_613590, JString, required = true,
                                 default = nil)
  if valid_613590 != nil:
    section.add "DeploymentStrategyId", valid_613590
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
  var valid_613591 = header.getOrDefault("X-Amz-Signature")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Signature", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Content-Sha256", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Date")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Date", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Credential")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Credential", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Security-Token")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Security-Token", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Algorithm")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Algorithm", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-SignedHeaders", valid_613597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613598: Call_GetDeploymentStrategy_613587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_613598.validator(path, query, header, formData, body)
  let scheme = call_613598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613598.url(scheme.get, call_613598.host, call_613598.base,
                         call_613598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613598, url, valid)

proc call*(call_613599: Call_GetDeploymentStrategy_613587;
          DeploymentStrategyId: string): Recallable =
  ## getDeploymentStrategy
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy to get.
  var path_613600 = newJObject()
  add(path_613600, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_613599.call(path_613600, nil, nil, nil, nil)

var getDeploymentStrategy* = Call_GetDeploymentStrategy_613587(
    name: "getDeploymentStrategy", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_GetDeploymentStrategy_613588, base: "/",
    url: url_GetDeploymentStrategy_613589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentStrategy_613601 = ref object of OpenApiRestCall_612658
proc url_UpdateDeploymentStrategy_613603(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDeploymentStrategy_613602(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a deployment strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The deployment strategy ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_613604 = path.getOrDefault("DeploymentStrategyId")
  valid_613604 = validateParameter(valid_613604, JString, required = true,
                                 default = nil)
  if valid_613604 != nil:
    section.add "DeploymentStrategyId", valid_613604
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
  var valid_613605 = header.getOrDefault("X-Amz-Signature")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Signature", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Content-Sha256", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Date")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Date", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Credential")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Credential", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Security-Token")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Security-Token", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Algorithm")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Algorithm", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-SignedHeaders", valid_613611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613613: Call_UpdateDeploymentStrategy_613601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a deployment strategy.
  ## 
  let valid = call_613613.validator(path, query, header, formData, body)
  let scheme = call_613613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613613.url(scheme.get, call_613613.host, call_613613.base,
                         call_613613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613613, url, valid)

proc call*(call_613614: Call_UpdateDeploymentStrategy_613601;
          DeploymentStrategyId: string; body: JsonNode): Recallable =
  ## updateDeploymentStrategy
  ## Updates a deployment strategy.
  ##   DeploymentStrategyId: string (required)
  ##                       : The deployment strategy ID.
  ##   body: JObject (required)
  var path_613615 = newJObject()
  var body_613616 = newJObject()
  add(path_613615, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  if body != nil:
    body_613616 = body
  result = call_613614.call(path_613615, nil, nil, nil, body_613616)

var updateDeploymentStrategy* = Call_UpdateDeploymentStrategy_613601(
    name: "updateDeploymentStrategy", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_UpdateDeploymentStrategy_613602, base: "/",
    url: url_UpdateDeploymentStrategy_613603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_613637 = ref object of OpenApiRestCall_612658
proc url_StartDeployment_613639(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartDeployment_613638(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Starts a deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EnvironmentId` field"
  var valid_613640 = path.getOrDefault("EnvironmentId")
  valid_613640 = validateParameter(valid_613640, JString, required = true,
                                 default = nil)
  if valid_613640 != nil:
    section.add "EnvironmentId", valid_613640
  var valid_613641 = path.getOrDefault("ApplicationId")
  valid_613641 = validateParameter(valid_613641, JString, required = true,
                                 default = nil)
  if valid_613641 != nil:
    section.add "ApplicationId", valid_613641
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
  var valid_613642 = header.getOrDefault("X-Amz-Signature")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Signature", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Content-Sha256", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Date")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Date", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Credential")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Credential", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Security-Token")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Security-Token", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Algorithm")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Algorithm", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-SignedHeaders", valid_613648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613650: Call_StartDeployment_613637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a deployment.
  ## 
  let valid = call_613650.validator(path, query, header, formData, body)
  let scheme = call_613650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613650.url(scheme.get, call_613650.host, call_613650.base,
                         call_613650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613650, url, valid)

proc call*(call_613651: Call_StartDeployment_613637; EnvironmentId: string;
          ApplicationId: string; body: JsonNode): Recallable =
  ## startDeployment
  ## Starts a deployment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_613652 = newJObject()
  var body_613653 = newJObject()
  add(path_613652, "EnvironmentId", newJString(EnvironmentId))
  add(path_613652, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_613653 = body
  result = call_613651.call(path_613652, nil, nil, nil, body_613653)

var startDeployment* = Call_StartDeployment_613637(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_StartDeployment_613638, base: "/", url: url_StartDeployment_613639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_613617 = ref object of OpenApiRestCall_612658
proc url_ListDeployments_613619(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDeployments_613618(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the deployments for an environment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EnvironmentId` field"
  var valid_613620 = path.getOrDefault("EnvironmentId")
  valid_613620 = validateParameter(valid_613620, JString, required = true,
                                 default = nil)
  if valid_613620 != nil:
    section.add "EnvironmentId", valid_613620
  var valid_613621 = path.getOrDefault("ApplicationId")
  valid_613621 = validateParameter(valid_613621, JString, required = true,
                                 default = nil)
  if valid_613621 != nil:
    section.add "ApplicationId", valid_613621
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  section = newJObject()
  var valid_613622 = query.getOrDefault("MaxResults")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "MaxResults", valid_613622
  var valid_613623 = query.getOrDefault("NextToken")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "NextToken", valid_613623
  var valid_613624 = query.getOrDefault("next_token")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "next_token", valid_613624
  var valid_613625 = query.getOrDefault("max_results")
  valid_613625 = validateParameter(valid_613625, JInt, required = false, default = nil)
  if valid_613625 != nil:
    section.add "max_results", valid_613625
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
  var valid_613626 = header.getOrDefault("X-Amz-Signature")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Signature", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Content-Sha256", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Date")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Date", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Credential")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Credential", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Security-Token")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Security-Token", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Algorithm")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Algorithm", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-SignedHeaders", valid_613632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613633: Call_ListDeployments_613617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployments for an environment.
  ## 
  let valid = call_613633.validator(path, query, header, formData, body)
  let scheme = call_613633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613633.url(scheme.get, call_613633.host, call_613633.base,
                         call_613633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613633, url, valid)

proc call*(call_613634: Call_ListDeployments_613617; EnvironmentId: string;
          ApplicationId: string; MaxResults: string = ""; NextToken: string = "";
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDeployments
  ## Lists the deployments for an environment.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  var path_613635 = newJObject()
  var query_613636 = newJObject()
  add(query_613636, "MaxResults", newJString(MaxResults))
  add(query_613636, "NextToken", newJString(NextToken))
  add(path_613635, "EnvironmentId", newJString(EnvironmentId))
  add(query_613636, "next_token", newJString(nextToken))
  add(path_613635, "ApplicationId", newJString(ApplicationId))
  add(query_613636, "max_results", newJInt(maxResults))
  result = call_613634.call(path_613635, query_613636, nil, nil, nil)

var listDeployments* = Call_ListDeployments_613617(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_ListDeployments_613618, base: "/", url: url_ListDeployments_613619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613668 = ref object of OpenApiRestCall_612658
proc url_TagResource_613670(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613669(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613671 = path.getOrDefault("ResourceArn")
  valid_613671 = validateParameter(valid_613671, JString, required = true,
                                 default = nil)
  if valid_613671 != nil:
    section.add "ResourceArn", valid_613671
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
  var valid_613672 = header.getOrDefault("X-Amz-Signature")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Signature", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Content-Sha256", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Date")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Date", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Credential")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Credential", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Security-Token")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Security-Token", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Algorithm")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Algorithm", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-SignedHeaders", valid_613678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613680: Call_TagResource_613668; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ## 
  let valid = call_613680.validator(path, query, header, formData, body)
  let scheme = call_613680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613680.url(scheme.get, call_613680.host, call_613680.base,
                         call_613680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613680, url, valid)

proc call*(call_613681: Call_TagResource_613668; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to retrieve tags.
  ##   body: JObject (required)
  var path_613682 = newJObject()
  var body_613683 = newJObject()
  add(path_613682, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_613683 = body
  result = call_613681.call(path_613682, nil, nil, nil, body_613683)

var tagResource* = Call_TagResource_613668(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appconfig.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_613669,
                                        base: "/", url: url_TagResource_613670,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613654 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613656(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613655(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_613657 = path.getOrDefault("ResourceArn")
  valid_613657 = validateParameter(valid_613657, JString, required = true,
                                 default = nil)
  if valid_613657 != nil:
    section.add "ResourceArn", valid_613657
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
  var valid_613658 = header.getOrDefault("X-Amz-Signature")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Signature", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Content-Sha256", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Date")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Date", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Credential")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Credential", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Security-Token")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Security-Token", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Algorithm")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Algorithm", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-SignedHeaders", valid_613664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613665: Call_ListTagsForResource_613654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of key-value tags assigned to the resource.
  ## 
  let valid = call_613665.validator(path, query, header, formData, body)
  let scheme = call_613665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613665.url(scheme.get, call_613665.host, call_613665.base,
                         call_613665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613665, url, valid)

proc call*(call_613666: Call_ListTagsForResource_613654; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves the list of key-value tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The resource ARN.
  var path_613667 = newJObject()
  add(path_613667, "ResourceArn", newJString(ResourceArn))
  result = call_613666.call(path_613667, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613654(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_613655, base: "/",
    url: url_ListTagsForResource_613656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613684 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613686(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613685(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_613687 = path.getOrDefault("ResourceArn")
  valid_613687 = validateParameter(valid_613687, JString, required = true,
                                 default = nil)
  if valid_613687 != nil:
    section.add "ResourceArn", valid_613687
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613688 = query.getOrDefault("tagKeys")
  valid_613688 = validateParameter(valid_613688, JArray, required = true, default = nil)
  if valid_613688 != nil:
    section.add "tagKeys", valid_613688
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
  var valid_613689 = header.getOrDefault("X-Amz-Signature")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Signature", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Content-Sha256", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Date")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Date", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Credential")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Credential", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613696: Call_UntagResource_613684; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a tag key and value from an AppConfig resource.
  ## 
  let valid = call_613696.validator(path, query, header, formData, body)
  let scheme = call_613696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613696.url(scheme.get, call_613696.host, call_613696.base,
                         call_613696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613696, url, valid)

proc call*(call_613697: Call_UntagResource_613684; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a tag key and value from an AppConfig resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to remove tags.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  var path_613698 = newJObject()
  var query_613699 = newJObject()
  add(path_613698, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_613699.add "tagKeys", tagKeys
  result = call_613697.call(path_613698, query_613699, nil, nil, nil)

var untagResource* = Call_UntagResource_613684(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_613685,
    base: "/", url: url_UntagResource_613686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidateConfiguration_613700 = ref object of OpenApiRestCall_612658
proc url_ValidateConfiguration_613702(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ValidateConfiguration_613701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Uses the validators in a configuration profile to validate a configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  ##   ConfigurationProfileId: JString (required)
  ##                         : The configuration profile ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_613703 = path.getOrDefault("ApplicationId")
  valid_613703 = validateParameter(valid_613703, JString, required = true,
                                 default = nil)
  if valid_613703 != nil:
    section.add "ApplicationId", valid_613703
  var valid_613704 = path.getOrDefault("ConfigurationProfileId")
  valid_613704 = validateParameter(valid_613704, JString, required = true,
                                 default = nil)
  if valid_613704 != nil:
    section.add "ConfigurationProfileId", valid_613704
  result.add "path", section
  ## parameters in `query` object:
  ##   configuration_version: JString (required)
  ##                        : The version of the configuration to validate.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `configuration_version` field"
  var valid_613705 = query.getOrDefault("configuration_version")
  valid_613705 = validateParameter(valid_613705, JString, required = true,
                                 default = nil)
  if valid_613705 != nil:
    section.add "configuration_version", valid_613705
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
  var valid_613706 = header.getOrDefault("X-Amz-Signature")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Signature", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Content-Sha256", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Date")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Date", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Credential")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Credential", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Security-Token")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Security-Token", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Algorithm")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Algorithm", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-SignedHeaders", valid_613712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613713: Call_ValidateConfiguration_613700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uses the validators in a configuration profile to validate a configuration.
  ## 
  let valid = call_613713.validator(path, query, header, formData, body)
  let scheme = call_613713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613713.url(scheme.get, call_613713.host, call_613713.base,
                         call_613713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613713, url, valid)

proc call*(call_613714: Call_ValidateConfiguration_613700; ApplicationId: string;
          ConfigurationProfileId: string; configurationVersion: string): Recallable =
  ## validateConfiguration
  ## Uses the validators in a configuration profile to validate a configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   ConfigurationProfileId: string (required)
  ##                         : The configuration profile ID.
  ##   configurationVersion: string (required)
  ##                       : The version of the configuration to validate.
  var path_613715 = newJObject()
  var query_613716 = newJObject()
  add(path_613715, "ApplicationId", newJString(ApplicationId))
  add(path_613715, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(query_613716, "configuration_version", newJString(configurationVersion))
  result = call_613714.call(path_613715, query_613716, nil, nil, nil)

var validateConfiguration* = Call_ValidateConfiguration_613700(
    name: "validateConfiguration", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}/validators#configuration_version",
    validator: validate_ValidateConfiguration_613701, base: "/",
    url: url_ValidateConfiguration_613702, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
