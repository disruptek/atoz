
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_CreateApplication_606186 = ref object of OpenApiRestCall_605589
proc url_CreateApplication_606188(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApplication_606187(path: JsonNode; query: JsonNode;
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
  var valid_606189 = header.getOrDefault("X-Amz-Signature")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Signature", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Content-Sha256", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Date")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Date", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Credential")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Credential", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Security-Token")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Security-Token", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Algorithm")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Algorithm", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-SignedHeaders", valid_606195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606197: Call_CreateApplication_606186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ## 
  let valid = call_606197.validator(path, query, header, formData, body)
  let scheme = call_606197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606197.url(scheme.get, call_606197.host, call_606197.base,
                         call_606197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606197, url, valid)

proc call*(call_606198: Call_CreateApplication_606186; body: JsonNode): Recallable =
  ## createApplication
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ##   body: JObject (required)
  var body_606199 = newJObject()
  if body != nil:
    body_606199 = body
  result = call_606198.call(nil, nil, nil, nil, body_606199)

var createApplication* = Call_CreateApplication_606186(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_606187, base: "/",
    url: url_CreateApplication_606188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_605927 = ref object of OpenApiRestCall_605589
proc url_ListApplications_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ListApplications_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = query.getOrDefault("MaxResults")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "MaxResults", valid_606041
  var valid_606042 = query.getOrDefault("NextToken")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "NextToken", valid_606042
  var valid_606043 = query.getOrDefault("next_token")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "next_token", valid_606043
  var valid_606044 = query.getOrDefault("max_results")
  valid_606044 = validateParameter(valid_606044, JInt, required = false, default = nil)
  if valid_606044 != nil:
    section.add "max_results", valid_606044
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
  var valid_606045 = header.getOrDefault("X-Amz-Signature")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Signature", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Content-Sha256", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Date")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Date", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Credential")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Credential", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Security-Token")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Security-Token", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Algorithm")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Algorithm", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-SignedHeaders", valid_606051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606074: Call_ListApplications_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all applications in your AWS account.
  ## 
  let valid = call_606074.validator(path, query, header, formData, body)
  let scheme = call_606074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606074.url(scheme.get, call_606074.host, call_606074.base,
                         call_606074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606074, url, valid)

proc call*(call_606145: Call_ListApplications_605927; MaxResults: string = "";
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
  var query_606146 = newJObject()
  add(query_606146, "MaxResults", newJString(MaxResults))
  add(query_606146, "NextToken", newJString(NextToken))
  add(query_606146, "next_token", newJString(nextToken))
  add(query_606146, "max_results", newJInt(maxResults))
  result = call_606145.call(nil, query_606146, nil, nil, nil)

var listApplications* = Call_ListApplications_605927(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_605928, base: "/",
    url: url_ListApplications_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationProfile_606233 = ref object of OpenApiRestCall_605589
proc url_CreateConfigurationProfile_606235(protocol: Scheme; host: string;
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

proc validate_CreateConfigurationProfile_606234(path: JsonNode; query: JsonNode;
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
  var valid_606236 = path.getOrDefault("ApplicationId")
  valid_606236 = validateParameter(valid_606236, JString, required = true,
                                 default = nil)
  if valid_606236 != nil:
    section.add "ApplicationId", valid_606236
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
  var valid_606237 = header.getOrDefault("X-Amz-Signature")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Signature", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Content-Sha256", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Date")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Date", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Credential")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Credential", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Security-Token")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Security-Token", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Algorithm")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Algorithm", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-SignedHeaders", valid_606243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606245: Call_CreateConfigurationProfile_606233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ## 
  let valid = call_606245.validator(path, query, header, formData, body)
  let scheme = call_606245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606245.url(scheme.get, call_606245.host, call_606245.base,
                         call_606245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606245, url, valid)

proc call*(call_606246: Call_CreateConfigurationProfile_606233;
          ApplicationId: string; body: JsonNode): Recallable =
  ## createConfigurationProfile
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_606247 = newJObject()
  var body_606248 = newJObject()
  add(path_606247, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_606248 = body
  result = call_606246.call(path_606247, nil, nil, nil, body_606248)

var createConfigurationProfile* = Call_CreateConfigurationProfile_606233(
    name: "createConfigurationProfile", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_CreateConfigurationProfile_606234, base: "/",
    url: url_CreateConfigurationProfile_606235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationProfiles_606200 = ref object of OpenApiRestCall_605589
proc url_ListConfigurationProfiles_606202(protocol: Scheme; host: string;
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

proc validate_ListConfigurationProfiles_606201(path: JsonNode; query: JsonNode;
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
  var valid_606217 = path.getOrDefault("ApplicationId")
  valid_606217 = validateParameter(valid_606217, JString, required = true,
                                 default = nil)
  if valid_606217 != nil:
    section.add "ApplicationId", valid_606217
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
  var valid_606218 = query.getOrDefault("MaxResults")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "MaxResults", valid_606218
  var valid_606219 = query.getOrDefault("NextToken")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "NextToken", valid_606219
  var valid_606220 = query.getOrDefault("next_token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "next_token", valid_606220
  var valid_606221 = query.getOrDefault("max_results")
  valid_606221 = validateParameter(valid_606221, JInt, required = false, default = nil)
  if valid_606221 != nil:
    section.add "max_results", valid_606221
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
  var valid_606222 = header.getOrDefault("X-Amz-Signature")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Signature", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Content-Sha256", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Date")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Date", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Credential")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Credential", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Security-Token")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Security-Token", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Algorithm")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Algorithm", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-SignedHeaders", valid_606228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606229: Call_ListConfigurationProfiles_606200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the configuration profiles for an application.
  ## 
  let valid = call_606229.validator(path, query, header, formData, body)
  let scheme = call_606229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606229.url(scheme.get, call_606229.host, call_606229.base,
                         call_606229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606229, url, valid)

proc call*(call_606230: Call_ListConfigurationProfiles_606200;
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
  var path_606231 = newJObject()
  var query_606232 = newJObject()
  add(query_606232, "MaxResults", newJString(MaxResults))
  add(query_606232, "NextToken", newJString(NextToken))
  add(query_606232, "next_token", newJString(nextToken))
  add(path_606231, "ApplicationId", newJString(ApplicationId))
  add(query_606232, "max_results", newJInt(maxResults))
  result = call_606230.call(path_606231, query_606232, nil, nil, nil)

var listConfigurationProfiles* = Call_ListConfigurationProfiles_606200(
    name: "listConfigurationProfiles", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_ListConfigurationProfiles_606201, base: "/",
    url: url_ListConfigurationProfiles_606202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentStrategy_606266 = ref object of OpenApiRestCall_605589
proc url_CreateDeploymentStrategy_606268(protocol: Scheme; host: string;
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

proc validate_CreateDeploymentStrategy_606267(path: JsonNode; query: JsonNode;
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
  var valid_606269 = header.getOrDefault("X-Amz-Signature")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Signature", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Content-Sha256", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Date")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Date", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Credential")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Credential", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Security-Token")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Security-Token", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Algorithm")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Algorithm", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-SignedHeaders", valid_606275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606277: Call_CreateDeploymentStrategy_606266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_606277.validator(path, query, header, formData, body)
  let scheme = call_606277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606277.url(scheme.get, call_606277.host, call_606277.base,
                         call_606277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606277, url, valid)

proc call*(call_606278: Call_CreateDeploymentStrategy_606266; body: JsonNode): Recallable =
  ## createDeploymentStrategy
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   body: JObject (required)
  var body_606279 = newJObject()
  if body != nil:
    body_606279 = body
  result = call_606278.call(nil, nil, nil, nil, body_606279)

var createDeploymentStrategy* = Call_CreateDeploymentStrategy_606266(
    name: "createDeploymentStrategy", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_CreateDeploymentStrategy_606267, base: "/",
    url: url_CreateDeploymentStrategy_606268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentStrategies_606249 = ref object of OpenApiRestCall_605589
proc url_ListDeploymentStrategies_606251(protocol: Scheme; host: string;
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

proc validate_ListDeploymentStrategies_606250(path: JsonNode; query: JsonNode;
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
  var valid_606252 = query.getOrDefault("MaxResults")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "MaxResults", valid_606252
  var valid_606253 = query.getOrDefault("NextToken")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "NextToken", valid_606253
  var valid_606254 = query.getOrDefault("next_token")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "next_token", valid_606254
  var valid_606255 = query.getOrDefault("max_results")
  valid_606255 = validateParameter(valid_606255, JInt, required = false, default = nil)
  if valid_606255 != nil:
    section.add "max_results", valid_606255
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
  var valid_606256 = header.getOrDefault("X-Amz-Signature")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Signature", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Content-Sha256", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Date")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Date", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Credential")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Credential", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Security-Token")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Security-Token", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Algorithm")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Algorithm", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-SignedHeaders", valid_606262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606263: Call_ListDeploymentStrategies_606249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List deployment strategies.
  ## 
  let valid = call_606263.validator(path, query, header, formData, body)
  let scheme = call_606263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606263.url(scheme.get, call_606263.host, call_606263.base,
                         call_606263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606263, url, valid)

proc call*(call_606264: Call_ListDeploymentStrategies_606249;
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
  var query_606265 = newJObject()
  add(query_606265, "MaxResults", newJString(MaxResults))
  add(query_606265, "NextToken", newJString(NextToken))
  add(query_606265, "next_token", newJString(nextToken))
  add(query_606265, "max_results", newJInt(maxResults))
  result = call_606264.call(nil, query_606265, nil, nil, nil)

var listDeploymentStrategies* = Call_ListDeploymentStrategies_606249(
    name: "listDeploymentStrategies", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_ListDeploymentStrategies_606250, base: "/",
    url: url_ListDeploymentStrategies_606251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironment_606299 = ref object of OpenApiRestCall_605589
proc url_CreateEnvironment_606301(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEnvironment_606300(path: JsonNode; query: JsonNode;
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
  var valid_606302 = path.getOrDefault("ApplicationId")
  valid_606302 = validateParameter(valid_606302, JString, required = true,
                                 default = nil)
  if valid_606302 != nil:
    section.add "ApplicationId", valid_606302
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
  var valid_606303 = header.getOrDefault("X-Amz-Signature")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Signature", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Content-Sha256", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Date")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Date", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Credential")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Credential", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Security-Token")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Security-Token", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Algorithm")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Algorithm", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-SignedHeaders", valid_606309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606311: Call_CreateEnvironment_606299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ## 
  let valid = call_606311.validator(path, query, header, formData, body)
  let scheme = call_606311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606311.url(scheme.get, call_606311.host, call_606311.base,
                         call_606311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606311, url, valid)

proc call*(call_606312: Call_CreateEnvironment_606299; ApplicationId: string;
          body: JsonNode): Recallable =
  ## createEnvironment
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_606313 = newJObject()
  var body_606314 = newJObject()
  add(path_606313, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_606314 = body
  result = call_606312.call(path_606313, nil, nil, nil, body_606314)

var createEnvironment* = Call_CreateEnvironment_606299(name: "createEnvironment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_CreateEnvironment_606300, base: "/",
    url: url_CreateEnvironment_606301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_606280 = ref object of OpenApiRestCall_605589
proc url_ListEnvironments_606282(protocol: Scheme; host: string; base: string;
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

proc validate_ListEnvironments_606281(path: JsonNode; query: JsonNode;
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
  var valid_606283 = path.getOrDefault("ApplicationId")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "ApplicationId", valid_606283
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
  var valid_606284 = query.getOrDefault("MaxResults")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "MaxResults", valid_606284
  var valid_606285 = query.getOrDefault("NextToken")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "NextToken", valid_606285
  var valid_606286 = query.getOrDefault("next_token")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "next_token", valid_606286
  var valid_606287 = query.getOrDefault("max_results")
  valid_606287 = validateParameter(valid_606287, JInt, required = false, default = nil)
  if valid_606287 != nil:
    section.add "max_results", valid_606287
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
  var valid_606288 = header.getOrDefault("X-Amz-Signature")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Signature", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Content-Sha256", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Date")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Date", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Credential")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Credential", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Security-Token")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Security-Token", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Algorithm")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Algorithm", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-SignedHeaders", valid_606294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606295: Call_ListEnvironments_606280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the environments for an application.
  ## 
  let valid = call_606295.validator(path, query, header, formData, body)
  let scheme = call_606295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606295.url(scheme.get, call_606295.host, call_606295.base,
                         call_606295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606295, url, valid)

proc call*(call_606296: Call_ListEnvironments_606280; ApplicationId: string;
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
  var path_606297 = newJObject()
  var query_606298 = newJObject()
  add(query_606298, "MaxResults", newJString(MaxResults))
  add(query_606298, "NextToken", newJString(NextToken))
  add(query_606298, "next_token", newJString(nextToken))
  add(path_606297, "ApplicationId", newJString(ApplicationId))
  add(query_606298, "max_results", newJInt(maxResults))
  result = call_606296.call(path_606297, query_606298, nil, nil, nil)

var listEnvironments* = Call_ListEnvironments_606280(name: "listEnvironments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_ListEnvironments_606281, base: "/",
    url: url_ListEnvironments_606282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_606315 = ref object of OpenApiRestCall_605589
proc url_GetApplication_606317(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplication_606316(path: JsonNode; query: JsonNode;
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
  var valid_606318 = path.getOrDefault("ApplicationId")
  valid_606318 = validateParameter(valid_606318, JString, required = true,
                                 default = nil)
  if valid_606318 != nil:
    section.add "ApplicationId", valid_606318
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
  var valid_606319 = header.getOrDefault("X-Amz-Signature")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Signature", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Content-Sha256", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Date")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Date", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Credential")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Credential", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Security-Token")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Security-Token", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Algorithm")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Algorithm", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-SignedHeaders", valid_606325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606326: Call_GetApplication_606315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_606326.validator(path, query, header, formData, body)
  let scheme = call_606326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606326.url(scheme.get, call_606326.host, call_606326.base,
                         call_606326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606326, url, valid)

proc call*(call_606327: Call_GetApplication_606315; ApplicationId: string): Recallable =
  ## getApplication
  ## Retrieve information about an application.
  ##   ApplicationId: string (required)
  ##                : The ID of the application you want to get.
  var path_606328 = newJObject()
  add(path_606328, "ApplicationId", newJString(ApplicationId))
  result = call_606327.call(path_606328, nil, nil, nil, nil)

var getApplication* = Call_GetApplication_606315(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_GetApplication_606316,
    base: "/", url: url_GetApplication_606317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_606343 = ref object of OpenApiRestCall_605589
proc url_UpdateApplication_606345(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApplication_606344(path: JsonNode; query: JsonNode;
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
  var valid_606346 = path.getOrDefault("ApplicationId")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "ApplicationId", valid_606346
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
  var valid_606347 = header.getOrDefault("X-Amz-Signature")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Signature", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Content-Sha256", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Date")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Date", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Credential")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Credential", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Security-Token")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Security-Token", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Algorithm")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Algorithm", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-SignedHeaders", valid_606353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606355: Call_UpdateApplication_606343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_606355.validator(path, query, header, formData, body)
  let scheme = call_606355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606355.url(scheme.get, call_606355.host, call_606355.base,
                         call_606355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606355, url, valid)

proc call*(call_606356: Call_UpdateApplication_606343; ApplicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates an application.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_606357 = newJObject()
  var body_606358 = newJObject()
  add(path_606357, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_606358 = body
  result = call_606356.call(path_606357, nil, nil, nil, body_606358)

var updateApplication* = Call_UpdateApplication_606343(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_UpdateApplication_606344,
    base: "/", url: url_UpdateApplication_606345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_606329 = ref object of OpenApiRestCall_605589
proc url_DeleteApplication_606331(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApplication_606330(path: JsonNode; query: JsonNode;
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
  var valid_606332 = path.getOrDefault("ApplicationId")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = nil)
  if valid_606332 != nil:
    section.add "ApplicationId", valid_606332
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
  var valid_606333 = header.getOrDefault("X-Amz-Signature")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Signature", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Content-Sha256", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Date")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Date", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Credential")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Credential", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Security-Token")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Security-Token", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Algorithm")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Algorithm", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-SignedHeaders", valid_606339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606340: Call_DeleteApplication_606329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ## 
  let valid = call_606340.validator(path, query, header, formData, body)
  let scheme = call_606340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606340.url(scheme.get, call_606340.host, call_606340.base,
                         call_606340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606340, url, valid)

proc call*(call_606341: Call_DeleteApplication_606329; ApplicationId: string): Recallable =
  ## deleteApplication
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The ID of the application to delete.
  var path_606342 = newJObject()
  add(path_606342, "ApplicationId", newJString(ApplicationId))
  result = call_606341.call(path_606342, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_606329(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_DeleteApplication_606330,
    base: "/", url: url_DeleteApplication_606331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationProfile_606359 = ref object of OpenApiRestCall_605589
proc url_GetConfigurationProfile_606361(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfigurationProfile_606360(path: JsonNode; query: JsonNode;
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
  var valid_606362 = path.getOrDefault("ApplicationId")
  valid_606362 = validateParameter(valid_606362, JString, required = true,
                                 default = nil)
  if valid_606362 != nil:
    section.add "ApplicationId", valid_606362
  var valid_606363 = path.getOrDefault("ConfigurationProfileId")
  valid_606363 = validateParameter(valid_606363, JString, required = true,
                                 default = nil)
  if valid_606363 != nil:
    section.add "ConfigurationProfileId", valid_606363
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
  var valid_606364 = header.getOrDefault("X-Amz-Signature")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Signature", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Content-Sha256", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Date")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Date", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Credential")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Credential", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Security-Token")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Security-Token", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Algorithm")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Algorithm", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-SignedHeaders", valid_606370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606371: Call_GetConfigurationProfile_606359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration profile.
  ## 
  let valid = call_606371.validator(path, query, header, formData, body)
  let scheme = call_606371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606371.url(scheme.get, call_606371.host, call_606371.base,
                         call_606371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606371, url, valid)

proc call*(call_606372: Call_GetConfigurationProfile_606359; ApplicationId: string;
          ConfigurationProfileId: string): Recallable =
  ## getConfigurationProfile
  ## Retrieve information about a configuration profile.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the configuration profile you want to get.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to get.
  var path_606373 = newJObject()
  add(path_606373, "ApplicationId", newJString(ApplicationId))
  add(path_606373, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_606372.call(path_606373, nil, nil, nil, nil)

var getConfigurationProfile* = Call_GetConfigurationProfile_606359(
    name: "getConfigurationProfile", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_GetConfigurationProfile_606360, base: "/",
    url: url_GetConfigurationProfile_606361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationProfile_606389 = ref object of OpenApiRestCall_605589
proc url_UpdateConfigurationProfile_606391(protocol: Scheme; host: string;
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

proc validate_UpdateConfigurationProfile_606390(path: JsonNode; query: JsonNode;
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
  var valid_606392 = path.getOrDefault("ApplicationId")
  valid_606392 = validateParameter(valid_606392, JString, required = true,
                                 default = nil)
  if valid_606392 != nil:
    section.add "ApplicationId", valid_606392
  var valid_606393 = path.getOrDefault("ConfigurationProfileId")
  valid_606393 = validateParameter(valid_606393, JString, required = true,
                                 default = nil)
  if valid_606393 != nil:
    section.add "ConfigurationProfileId", valid_606393
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
  var valid_606394 = header.getOrDefault("X-Amz-Signature")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Signature", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Content-Sha256", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Date")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Date", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Credential")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Credential", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Security-Token")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Security-Token", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Algorithm")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Algorithm", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-SignedHeaders", valid_606400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606402: Call_UpdateConfigurationProfile_606389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a configuration profile.
  ## 
  let valid = call_606402.validator(path, query, header, formData, body)
  let scheme = call_606402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606402.url(scheme.get, call_606402.host, call_606402.base,
                         call_606402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606402, url, valid)

proc call*(call_606403: Call_UpdateConfigurationProfile_606389;
          ApplicationId: string; body: JsonNode; ConfigurationProfileId: string): Recallable =
  ## updateConfigurationProfile
  ## Updates a configuration profile.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile.
  var path_606404 = newJObject()
  var body_606405 = newJObject()
  add(path_606404, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_606405 = body
  add(path_606404, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_606403.call(path_606404, nil, nil, nil, body_606405)

var updateConfigurationProfile* = Call_UpdateConfigurationProfile_606389(
    name: "updateConfigurationProfile", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_UpdateConfigurationProfile_606390, base: "/",
    url: url_UpdateConfigurationProfile_606391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationProfile_606374 = ref object of OpenApiRestCall_605589
proc url_DeleteConfigurationProfile_606376(protocol: Scheme; host: string;
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

proc validate_DeleteConfigurationProfile_606375(path: JsonNode; query: JsonNode;
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
  var valid_606377 = path.getOrDefault("ApplicationId")
  valid_606377 = validateParameter(valid_606377, JString, required = true,
                                 default = nil)
  if valid_606377 != nil:
    section.add "ApplicationId", valid_606377
  var valid_606378 = path.getOrDefault("ConfigurationProfileId")
  valid_606378 = validateParameter(valid_606378, JString, required = true,
                                 default = nil)
  if valid_606378 != nil:
    section.add "ConfigurationProfileId", valid_606378
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
  var valid_606379 = header.getOrDefault("X-Amz-Signature")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Signature", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Content-Sha256", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Date")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Date", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Credential")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Credential", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Security-Token")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Security-Token", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Algorithm")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Algorithm", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-SignedHeaders", valid_606385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606386: Call_DeleteConfigurationProfile_606374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ## 
  let valid = call_606386.validator(path, query, header, formData, body)
  let scheme = call_606386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606386.url(scheme.get, call_606386.host, call_606386.base,
                         call_606386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606386, url, valid)

proc call*(call_606387: Call_DeleteConfigurationProfile_606374;
          ApplicationId: string; ConfigurationProfileId: string): Recallable =
  ## deleteConfigurationProfile
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the configuration profile you want to delete.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to delete.
  var path_606388 = newJObject()
  add(path_606388, "ApplicationId", newJString(ApplicationId))
  add(path_606388, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_606387.call(path_606388, nil, nil, nil, nil)

var deleteConfigurationProfile* = Call_DeleteConfigurationProfile_606374(
    name: "deleteConfigurationProfile", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_DeleteConfigurationProfile_606375, base: "/",
    url: url_DeleteConfigurationProfile_606376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentStrategy_606406 = ref object of OpenApiRestCall_605589
proc url_DeleteDeploymentStrategy_606408(protocol: Scheme; host: string;
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

proc validate_DeleteDeploymentStrategy_606407(path: JsonNode; query: JsonNode;
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
  var valid_606409 = path.getOrDefault("DeploymentStrategyId")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = nil)
  if valid_606409 != nil:
    section.add "DeploymentStrategyId", valid_606409
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
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606417: Call_DeleteDeploymentStrategy_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  let valid = call_606417.validator(path, query, header, formData, body)
  let scheme = call_606417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606417.url(scheme.get, call_606417.host, call_606417.base,
                         call_606417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606417, url, valid)

proc call*(call_606418: Call_DeleteDeploymentStrategy_606406;
          DeploymentStrategyId: string): Recallable =
  ## deleteDeploymentStrategy
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy you want to delete.
  var path_606419 = newJObject()
  add(path_606419, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_606418.call(path_606419, nil, nil, nil, nil)

var deleteDeploymentStrategy* = Call_DeleteDeploymentStrategy_606406(
    name: "deleteDeploymentStrategy", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com",
    route: "/deployementstrategies/{DeploymentStrategyId}",
    validator: validate_DeleteDeploymentStrategy_606407, base: "/",
    url: url_DeleteDeploymentStrategy_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnvironment_606420 = ref object of OpenApiRestCall_605589
proc url_GetEnvironment_606422(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnvironment_606421(path: JsonNode; query: JsonNode;
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
  var valid_606423 = path.getOrDefault("EnvironmentId")
  valid_606423 = validateParameter(valid_606423, JString, required = true,
                                 default = nil)
  if valid_606423 != nil:
    section.add "EnvironmentId", valid_606423
  var valid_606424 = path.getOrDefault("ApplicationId")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = nil)
  if valid_606424 != nil:
    section.add "ApplicationId", valid_606424
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
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606432: Call_GetEnvironment_606420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ## 
  let valid = call_606432.validator(path, query, header, formData, body)
  let scheme = call_606432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606432.url(scheme.get, call_606432.host, call_606432.base,
                         call_606432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606432, url, valid)

proc call*(call_606433: Call_GetEnvironment_606420; EnvironmentId: string;
          ApplicationId: string): Recallable =
  ## getEnvironment
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you wnat to get.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the environment you want to get.
  var path_606434 = newJObject()
  add(path_606434, "EnvironmentId", newJString(EnvironmentId))
  add(path_606434, "ApplicationId", newJString(ApplicationId))
  result = call_606433.call(path_606434, nil, nil, nil, nil)

var getEnvironment* = Call_GetEnvironment_606420(name: "getEnvironment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_GetEnvironment_606421, base: "/", url: url_GetEnvironment_606422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_606450 = ref object of OpenApiRestCall_605589
proc url_UpdateEnvironment_606452(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEnvironment_606451(path: JsonNode; query: JsonNode;
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
  var valid_606453 = path.getOrDefault("EnvironmentId")
  valid_606453 = validateParameter(valid_606453, JString, required = true,
                                 default = nil)
  if valid_606453 != nil:
    section.add "EnvironmentId", valid_606453
  var valid_606454 = path.getOrDefault("ApplicationId")
  valid_606454 = validateParameter(valid_606454, JString, required = true,
                                 default = nil)
  if valid_606454 != nil:
    section.add "ApplicationId", valid_606454
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
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_UpdateEnvironment_606450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an environment.
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_UpdateEnvironment_606450; EnvironmentId: string;
          ApplicationId: string; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Updates an environment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_606465 = newJObject()
  var body_606466 = newJObject()
  add(path_606465, "EnvironmentId", newJString(EnvironmentId))
  add(path_606465, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_606466 = body
  result = call_606464.call(path_606465, nil, nil, nil, body_606466)

var updateEnvironment* = Call_UpdateEnvironment_606450(name: "updateEnvironment",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_UpdateEnvironment_606451, base: "/",
    url: url_UpdateEnvironment_606452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_606435 = ref object of OpenApiRestCall_605589
proc url_DeleteEnvironment_606437(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEnvironment_606436(path: JsonNode; query: JsonNode;
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
  var valid_606438 = path.getOrDefault("EnvironmentId")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = nil)
  if valid_606438 != nil:
    section.add "EnvironmentId", valid_606438
  var valid_606439 = path.getOrDefault("ApplicationId")
  valid_606439 = validateParameter(valid_606439, JString, required = true,
                                 default = nil)
  if valid_606439 != nil:
    section.add "ApplicationId", valid_606439
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
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606447: Call_DeleteEnvironment_606435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ## 
  let valid = call_606447.validator(path, query, header, formData, body)
  let scheme = call_606447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606447.url(scheme.get, call_606447.host, call_606447.base,
                         call_606447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606447, url, valid)

proc call*(call_606448: Call_DeleteEnvironment_606435; EnvironmentId: string;
          ApplicationId: string): Recallable =
  ## deleteEnvironment
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you want to delete.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the environment you want to delete.
  var path_606449 = newJObject()
  add(path_606449, "EnvironmentId", newJString(EnvironmentId))
  add(path_606449, "ApplicationId", newJString(ApplicationId))
  result = call_606448.call(path_606449, nil, nil, nil, nil)

var deleteEnvironment* = Call_DeleteEnvironment_606435(name: "deleteEnvironment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_DeleteEnvironment_606436, base: "/",
    url: url_DeleteEnvironment_606437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfiguration_606467 = ref object of OpenApiRestCall_605589
proc url_GetConfiguration_606469(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfiguration_606468(path: JsonNode; query: JsonNode;
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
  var valid_606470 = path.getOrDefault("Environment")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = nil)
  if valid_606470 != nil:
    section.add "Environment", valid_606470
  var valid_606471 = path.getOrDefault("Application")
  valid_606471 = validateParameter(valid_606471, JString, required = true,
                                 default = nil)
  if valid_606471 != nil:
    section.add "Application", valid_606471
  var valid_606472 = path.getOrDefault("Configuration")
  valid_606472 = validateParameter(valid_606472, JString, required = true,
                                 default = nil)
  if valid_606472 != nil:
    section.add "Configuration", valid_606472
  result.add "path", section
  ## parameters in `query` object:
  ##   client_id: JString (required)
  ##            : A unique ID to identify the client for the configuration. This ID enables AppConfig to deploy the configuration in intervals, as defined in the deployment strategy.
  ##   client_configuration_version: JString
  ##                               : The configuration version returned in the most recent GetConfiguration response.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `client_id` field"
  var valid_606473 = query.getOrDefault("client_id")
  valid_606473 = validateParameter(valid_606473, JString, required = true,
                                 default = nil)
  if valid_606473 != nil:
    section.add "client_id", valid_606473
  var valid_606474 = query.getOrDefault("client_configuration_version")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "client_configuration_version", valid_606474
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
  var valid_606475 = header.getOrDefault("X-Amz-Signature")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Signature", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Content-Sha256", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Date")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Date", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Credential")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Credential", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Security-Token")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Security-Token", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Algorithm")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Algorithm", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-SignedHeaders", valid_606481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606482: Call_GetConfiguration_606467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration.
  ## 
  let valid = call_606482.validator(path, query, header, formData, body)
  let scheme = call_606482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606482.url(scheme.get, call_606482.host, call_606482.base,
                         call_606482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606482, url, valid)

proc call*(call_606483: Call_GetConfiguration_606467; Environment: string;
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
  var path_606484 = newJObject()
  var query_606485 = newJObject()
  add(path_606484, "Environment", newJString(Environment))
  add(path_606484, "Application", newJString(Application))
  add(path_606484, "Configuration", newJString(Configuration))
  add(query_606485, "client_id", newJString(clientId))
  add(query_606485, "client_configuration_version",
      newJString(clientConfigurationVersion))
  result = call_606483.call(path_606484, query_606485, nil, nil, nil)

var getConfiguration* = Call_GetConfiguration_606467(name: "getConfiguration",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{Application}/environments/{Environment}/configurations/{Configuration}#client_id",
    validator: validate_GetConfiguration_606468, base: "/",
    url: url_GetConfiguration_606469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_606486 = ref object of OpenApiRestCall_605589
proc url_GetDeployment_606488(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_606487(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606489 = path.getOrDefault("DeploymentNumber")
  valid_606489 = validateParameter(valid_606489, JInt, required = true, default = nil)
  if valid_606489 != nil:
    section.add "DeploymentNumber", valid_606489
  var valid_606490 = path.getOrDefault("EnvironmentId")
  valid_606490 = validateParameter(valid_606490, JString, required = true,
                                 default = nil)
  if valid_606490 != nil:
    section.add "EnvironmentId", valid_606490
  var valid_606491 = path.getOrDefault("ApplicationId")
  valid_606491 = validateParameter(valid_606491, JString, required = true,
                                 default = nil)
  if valid_606491 != nil:
    section.add "ApplicationId", valid_606491
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
  var valid_606492 = header.getOrDefault("X-Amz-Signature")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Signature", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Content-Sha256", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Date")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Date", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Credential")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Credential", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Security-Token")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Security-Token", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Algorithm")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Algorithm", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-SignedHeaders", valid_606498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606499: Call_GetDeployment_606486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration deployment.
  ## 
  let valid = call_606499.validator(path, query, header, formData, body)
  let scheme = call_606499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606499.url(scheme.get, call_606499.host, call_606499.base,
                         call_606499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606499, url, valid)

proc call*(call_606500: Call_GetDeployment_606486; DeploymentNumber: int;
          EnvironmentId: string; ApplicationId: string): Recallable =
  ## getDeployment
  ## Retrieve information about a configuration deployment.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment that includes the deployment you want to get. 
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the deployment you want to get. 
  var path_606501 = newJObject()
  add(path_606501, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_606501, "EnvironmentId", newJString(EnvironmentId))
  add(path_606501, "ApplicationId", newJString(ApplicationId))
  result = call_606500.call(path_606501, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_606486(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_GetDeployment_606487, base: "/", url: url_GetDeployment_606488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_606502 = ref object of OpenApiRestCall_605589
proc url_StopDeployment_606504(protocol: Scheme; host: string; base: string;
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

proc validate_StopDeployment_606503(path: JsonNode; query: JsonNode;
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
  var valid_606505 = path.getOrDefault("DeploymentNumber")
  valid_606505 = validateParameter(valid_606505, JInt, required = true, default = nil)
  if valid_606505 != nil:
    section.add "DeploymentNumber", valid_606505
  var valid_606506 = path.getOrDefault("EnvironmentId")
  valid_606506 = validateParameter(valid_606506, JString, required = true,
                                 default = nil)
  if valid_606506 != nil:
    section.add "EnvironmentId", valid_606506
  var valid_606507 = path.getOrDefault("ApplicationId")
  valid_606507 = validateParameter(valid_606507, JString, required = true,
                                 default = nil)
  if valid_606507 != nil:
    section.add "ApplicationId", valid_606507
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
  var valid_606508 = header.getOrDefault("X-Amz-Signature")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Signature", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Content-Sha256", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Date")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Date", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Credential")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Credential", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Security-Token")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Security-Token", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Algorithm")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Algorithm", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-SignedHeaders", valid_606514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606515: Call_StopDeployment_606502; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ## 
  let valid = call_606515.validator(path, query, header, formData, body)
  let scheme = call_606515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606515.url(scheme.get, call_606515.host, call_606515.base,
                         call_606515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606515, url, valid)

proc call*(call_606516: Call_StopDeployment_606502; DeploymentNumber: int;
          EnvironmentId: string; ApplicationId: string): Recallable =
  ## stopDeployment
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  var path_606517 = newJObject()
  add(path_606517, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_606517, "EnvironmentId", newJString(EnvironmentId))
  add(path_606517, "ApplicationId", newJString(ApplicationId))
  result = call_606516.call(path_606517, nil, nil, nil, nil)

var stopDeployment* = Call_StopDeployment_606502(name: "stopDeployment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_StopDeployment_606503, base: "/", url: url_StopDeployment_606504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStrategy_606518 = ref object of OpenApiRestCall_605589
proc url_GetDeploymentStrategy_606520(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeploymentStrategy_606519(path: JsonNode; query: JsonNode;
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
  var valid_606521 = path.getOrDefault("DeploymentStrategyId")
  valid_606521 = validateParameter(valid_606521, JString, required = true,
                                 default = nil)
  if valid_606521 != nil:
    section.add "DeploymentStrategyId", valid_606521
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
  var valid_606522 = header.getOrDefault("X-Amz-Signature")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Signature", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Content-Sha256", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Date")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Date", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Credential")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Credential", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Security-Token")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Security-Token", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Algorithm")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Algorithm", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-SignedHeaders", valid_606528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606529: Call_GetDeploymentStrategy_606518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_606529.validator(path, query, header, formData, body)
  let scheme = call_606529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606529.url(scheme.get, call_606529.host, call_606529.base,
                         call_606529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606529, url, valid)

proc call*(call_606530: Call_GetDeploymentStrategy_606518;
          DeploymentStrategyId: string): Recallable =
  ## getDeploymentStrategy
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy to get.
  var path_606531 = newJObject()
  add(path_606531, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_606530.call(path_606531, nil, nil, nil, nil)

var getDeploymentStrategy* = Call_GetDeploymentStrategy_606518(
    name: "getDeploymentStrategy", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_GetDeploymentStrategy_606519, base: "/",
    url: url_GetDeploymentStrategy_606520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentStrategy_606532 = ref object of OpenApiRestCall_605589
proc url_UpdateDeploymentStrategy_606534(protocol: Scheme; host: string;
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

proc validate_UpdateDeploymentStrategy_606533(path: JsonNode; query: JsonNode;
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
  var valid_606535 = path.getOrDefault("DeploymentStrategyId")
  valid_606535 = validateParameter(valid_606535, JString, required = true,
                                 default = nil)
  if valid_606535 != nil:
    section.add "DeploymentStrategyId", valid_606535
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
  var valid_606536 = header.getOrDefault("X-Amz-Signature")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Signature", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Content-Sha256", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Date")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Date", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Credential")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Credential", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Security-Token")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Security-Token", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Algorithm")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Algorithm", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-SignedHeaders", valid_606542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606544: Call_UpdateDeploymentStrategy_606532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a deployment strategy.
  ## 
  let valid = call_606544.validator(path, query, header, formData, body)
  let scheme = call_606544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606544.url(scheme.get, call_606544.host, call_606544.base,
                         call_606544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606544, url, valid)

proc call*(call_606545: Call_UpdateDeploymentStrategy_606532;
          DeploymentStrategyId: string; body: JsonNode): Recallable =
  ## updateDeploymentStrategy
  ## Updates a deployment strategy.
  ##   DeploymentStrategyId: string (required)
  ##                       : The deployment strategy ID.
  ##   body: JObject (required)
  var path_606546 = newJObject()
  var body_606547 = newJObject()
  add(path_606546, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  if body != nil:
    body_606547 = body
  result = call_606545.call(path_606546, nil, nil, nil, body_606547)

var updateDeploymentStrategy* = Call_UpdateDeploymentStrategy_606532(
    name: "updateDeploymentStrategy", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_UpdateDeploymentStrategy_606533, base: "/",
    url: url_UpdateDeploymentStrategy_606534, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_606568 = ref object of OpenApiRestCall_605589
proc url_StartDeployment_606570(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_606569(path: JsonNode; query: JsonNode;
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
  var valid_606571 = path.getOrDefault("EnvironmentId")
  valid_606571 = validateParameter(valid_606571, JString, required = true,
                                 default = nil)
  if valid_606571 != nil:
    section.add "EnvironmentId", valid_606571
  var valid_606572 = path.getOrDefault("ApplicationId")
  valid_606572 = validateParameter(valid_606572, JString, required = true,
                                 default = nil)
  if valid_606572 != nil:
    section.add "ApplicationId", valid_606572
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
  var valid_606573 = header.getOrDefault("X-Amz-Signature")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Signature", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Content-Sha256", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Date")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Date", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Credential")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Credential", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Security-Token")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Security-Token", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Algorithm")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Algorithm", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-SignedHeaders", valid_606579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606581: Call_StartDeployment_606568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a deployment.
  ## 
  let valid = call_606581.validator(path, query, header, formData, body)
  let scheme = call_606581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606581.url(scheme.get, call_606581.host, call_606581.base,
                         call_606581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606581, url, valid)

proc call*(call_606582: Call_StartDeployment_606568; EnvironmentId: string;
          ApplicationId: string; body: JsonNode): Recallable =
  ## startDeployment
  ## Starts a deployment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_606583 = newJObject()
  var body_606584 = newJObject()
  add(path_606583, "EnvironmentId", newJString(EnvironmentId))
  add(path_606583, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_606584 = body
  result = call_606582.call(path_606583, nil, nil, nil, body_606584)

var startDeployment* = Call_StartDeployment_606568(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_StartDeployment_606569, base: "/", url: url_StartDeployment_606570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_606548 = ref object of OpenApiRestCall_605589
proc url_ListDeployments_606550(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_606549(path: JsonNode; query: JsonNode;
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
  var valid_606551 = path.getOrDefault("EnvironmentId")
  valid_606551 = validateParameter(valid_606551, JString, required = true,
                                 default = nil)
  if valid_606551 != nil:
    section.add "EnvironmentId", valid_606551
  var valid_606552 = path.getOrDefault("ApplicationId")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = nil)
  if valid_606552 != nil:
    section.add "ApplicationId", valid_606552
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
  var valid_606553 = query.getOrDefault("MaxResults")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "MaxResults", valid_606553
  var valid_606554 = query.getOrDefault("NextToken")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "NextToken", valid_606554
  var valid_606555 = query.getOrDefault("next_token")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "next_token", valid_606555
  var valid_606556 = query.getOrDefault("max_results")
  valid_606556 = validateParameter(valid_606556, JInt, required = false, default = nil)
  if valid_606556 != nil:
    section.add "max_results", valid_606556
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
  var valid_606557 = header.getOrDefault("X-Amz-Signature")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Signature", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Content-Sha256", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Date")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Date", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Credential")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Credential", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Security-Token")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Security-Token", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Algorithm")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Algorithm", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-SignedHeaders", valid_606563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606564: Call_ListDeployments_606548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployments for an environment.
  ## 
  let valid = call_606564.validator(path, query, header, formData, body)
  let scheme = call_606564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606564.url(scheme.get, call_606564.host, call_606564.base,
                         call_606564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606564, url, valid)

proc call*(call_606565: Call_ListDeployments_606548; EnvironmentId: string;
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
  var path_606566 = newJObject()
  var query_606567 = newJObject()
  add(query_606567, "MaxResults", newJString(MaxResults))
  add(query_606567, "NextToken", newJString(NextToken))
  add(path_606566, "EnvironmentId", newJString(EnvironmentId))
  add(query_606567, "next_token", newJString(nextToken))
  add(path_606566, "ApplicationId", newJString(ApplicationId))
  add(query_606567, "max_results", newJInt(maxResults))
  result = call_606565.call(path_606566, query_606567, nil, nil, nil)

var listDeployments* = Call_ListDeployments_606548(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_ListDeployments_606549, base: "/", url: url_ListDeployments_606550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606599 = ref object of OpenApiRestCall_605589
proc url_TagResource_606601(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606600(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606602 = path.getOrDefault("ResourceArn")
  valid_606602 = validateParameter(valid_606602, JString, required = true,
                                 default = nil)
  if valid_606602 != nil:
    section.add "ResourceArn", valid_606602
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
  var valid_606603 = header.getOrDefault("X-Amz-Signature")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Signature", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Content-Sha256", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Date")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Date", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Credential")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Credential", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Security-Token")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Security-Token", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Algorithm")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Algorithm", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-SignedHeaders", valid_606609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606611: Call_TagResource_606599; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ## 
  let valid = call_606611.validator(path, query, header, formData, body)
  let scheme = call_606611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606611.url(scheme.get, call_606611.host, call_606611.base,
                         call_606611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606611, url, valid)

proc call*(call_606612: Call_TagResource_606599; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to retrieve tags.
  ##   body: JObject (required)
  var path_606613 = newJObject()
  var body_606614 = newJObject()
  add(path_606613, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_606614 = body
  result = call_606612.call(path_606613, nil, nil, nil, body_606614)

var tagResource* = Call_TagResource_606599(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appconfig.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_606600,
                                        base: "/", url: url_TagResource_606601,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606585 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606587(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606586(path: JsonNode; query: JsonNode;
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
  var valid_606588 = path.getOrDefault("ResourceArn")
  valid_606588 = validateParameter(valid_606588, JString, required = true,
                                 default = nil)
  if valid_606588 != nil:
    section.add "ResourceArn", valid_606588
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
  var valid_606589 = header.getOrDefault("X-Amz-Signature")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Signature", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Content-Sha256", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Date")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Date", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Credential")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Credential", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Security-Token")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Security-Token", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Algorithm")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Algorithm", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-SignedHeaders", valid_606595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606596: Call_ListTagsForResource_606585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of key-value tags assigned to the resource.
  ## 
  let valid = call_606596.validator(path, query, header, formData, body)
  let scheme = call_606596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606596.url(scheme.get, call_606596.host, call_606596.base,
                         call_606596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606596, url, valid)

proc call*(call_606597: Call_ListTagsForResource_606585; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves the list of key-value tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The resource ARN.
  var path_606598 = newJObject()
  add(path_606598, "ResourceArn", newJString(ResourceArn))
  result = call_606597.call(path_606598, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606585(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_606586, base: "/",
    url: url_ListTagsForResource_606587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606615 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606617(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606616(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606618 = path.getOrDefault("ResourceArn")
  valid_606618 = validateParameter(valid_606618, JString, required = true,
                                 default = nil)
  if valid_606618 != nil:
    section.add "ResourceArn", valid_606618
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606619 = query.getOrDefault("tagKeys")
  valid_606619 = validateParameter(valid_606619, JArray, required = true, default = nil)
  if valid_606619 != nil:
    section.add "tagKeys", valid_606619
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
  var valid_606620 = header.getOrDefault("X-Amz-Signature")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Signature", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Content-Sha256", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Date")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Date", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Credential")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Credential", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606627: Call_UntagResource_606615; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a tag key and value from an AppConfig resource.
  ## 
  let valid = call_606627.validator(path, query, header, formData, body)
  let scheme = call_606627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606627.url(scheme.get, call_606627.host, call_606627.base,
                         call_606627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606627, url, valid)

proc call*(call_606628: Call_UntagResource_606615; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a tag key and value from an AppConfig resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to remove tags.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  var path_606629 = newJObject()
  var query_606630 = newJObject()
  add(path_606629, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_606630.add "tagKeys", tagKeys
  result = call_606628.call(path_606629, query_606630, nil, nil, nil)

var untagResource* = Call_UntagResource_606615(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_606616,
    base: "/", url: url_UntagResource_606617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidateConfiguration_606631 = ref object of OpenApiRestCall_605589
proc url_ValidateConfiguration_606633(protocol: Scheme; host: string; base: string;
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

proc validate_ValidateConfiguration_606632(path: JsonNode; query: JsonNode;
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
  var valid_606634 = path.getOrDefault("ApplicationId")
  valid_606634 = validateParameter(valid_606634, JString, required = true,
                                 default = nil)
  if valid_606634 != nil:
    section.add "ApplicationId", valid_606634
  var valid_606635 = path.getOrDefault("ConfigurationProfileId")
  valid_606635 = validateParameter(valid_606635, JString, required = true,
                                 default = nil)
  if valid_606635 != nil:
    section.add "ConfigurationProfileId", valid_606635
  result.add "path", section
  ## parameters in `query` object:
  ##   configuration_version: JString (required)
  ##                        : The version of the configuration to validate.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `configuration_version` field"
  var valid_606636 = query.getOrDefault("configuration_version")
  valid_606636 = validateParameter(valid_606636, JString, required = true,
                                 default = nil)
  if valid_606636 != nil:
    section.add "configuration_version", valid_606636
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
  var valid_606637 = header.getOrDefault("X-Amz-Signature")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Signature", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Content-Sha256", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Date")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Date", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Credential")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Credential", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Security-Token")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Security-Token", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Algorithm")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Algorithm", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-SignedHeaders", valid_606643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606644: Call_ValidateConfiguration_606631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uses the validators in a configuration profile to validate a configuration.
  ## 
  let valid = call_606644.validator(path, query, header, formData, body)
  let scheme = call_606644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606644.url(scheme.get, call_606644.host, call_606644.base,
                         call_606644.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606644, url, valid)

proc call*(call_606645: Call_ValidateConfiguration_606631; ApplicationId: string;
          ConfigurationProfileId: string; configurationVersion: string): Recallable =
  ## validateConfiguration
  ## Uses the validators in a configuration profile to validate a configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   ConfigurationProfileId: string (required)
  ##                         : The configuration profile ID.
  ##   configurationVersion: string (required)
  ##                       : The version of the configuration to validate.
  var path_606646 = newJObject()
  var query_606647 = newJObject()
  add(path_606646, "ApplicationId", newJString(ApplicationId))
  add(path_606646, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(query_606647, "configuration_version", newJString(configurationVersion))
  result = call_606645.call(path_606646, query_606647, nil, nil, nil)

var validateConfiguration* = Call_ValidateConfiguration_606631(
    name: "validateConfiguration", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}/validators#configuration_version",
    validator: validate_ValidateConfiguration_606632, base: "/",
    url: url_ValidateConfiguration_606633, schemes: {Scheme.Https, Scheme.Http})
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
