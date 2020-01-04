
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CreateApplication_601986 = ref object of OpenApiRestCall_601389
proc url_CreateApplication_601988(protocol: Scheme; host: string; base: string;
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

proc validate_CreateApplication_601987(path: JsonNode; query: JsonNode;
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
  var valid_601989 = header.getOrDefault("X-Amz-Signature")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Signature", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Date")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Date", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Credential")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Credential", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Algorithm")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Algorithm", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_CreateApplication_601986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ## 
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601997, url, valid)

proc call*(call_601998: Call_CreateApplication_601986; body: JsonNode): Recallable =
  ## createApplication
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ##   body: JObject (required)
  var body_601999 = newJObject()
  if body != nil:
    body_601999 = body
  result = call_601998.call(nil, nil, nil, nil, body_601999)

var createApplication* = Call_CreateApplication_601986(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_601987, base: "/",
    url: url_CreateApplication_601988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_601727 = ref object of OpenApiRestCall_601389
proc url_ListApplications_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ListApplications_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = query.getOrDefault("MaxResults")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "MaxResults", valid_601841
  var valid_601842 = query.getOrDefault("NextToken")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "NextToken", valid_601842
  var valid_601843 = query.getOrDefault("next_token")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "next_token", valid_601843
  var valid_601844 = query.getOrDefault("max_results")
  valid_601844 = validateParameter(valid_601844, JInt, required = false, default = nil)
  if valid_601844 != nil:
    section.add "max_results", valid_601844
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
  var valid_601845 = header.getOrDefault("X-Amz-Signature")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Signature", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Content-Sha256", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Date")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Date", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Credential")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Credential", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Security-Token")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Security-Token", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Algorithm")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Algorithm", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-SignedHeaders", valid_601851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601874: Call_ListApplications_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all applications in your AWS account.
  ## 
  let valid = call_601874.validator(path, query, header, formData, body)
  let scheme = call_601874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601874.url(scheme.get, call_601874.host, call_601874.base,
                         call_601874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601874, url, valid)

proc call*(call_601945: Call_ListApplications_601727; MaxResults: string = "";
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
  var query_601946 = newJObject()
  add(query_601946, "MaxResults", newJString(MaxResults))
  add(query_601946, "NextToken", newJString(NextToken))
  add(query_601946, "next_token", newJString(nextToken))
  add(query_601946, "max_results", newJInt(maxResults))
  result = call_601945.call(nil, query_601946, nil, nil, nil)

var listApplications* = Call_ListApplications_601727(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_601728, base: "/",
    url: url_ListApplications_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationProfile_602033 = ref object of OpenApiRestCall_601389
proc url_CreateConfigurationProfile_602035(protocol: Scheme; host: string;
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

proc validate_CreateConfigurationProfile_602034(path: JsonNode; query: JsonNode;
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
  var valid_602036 = path.getOrDefault("ApplicationId")
  valid_602036 = validateParameter(valid_602036, JString, required = true,
                                 default = nil)
  if valid_602036 != nil:
    section.add "ApplicationId", valid_602036
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
  var valid_602037 = header.getOrDefault("X-Amz-Signature")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Signature", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Content-Sha256", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Date")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Date", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Credential")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Credential", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Security-Token")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Security-Token", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Algorithm")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Algorithm", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-SignedHeaders", valid_602043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602045: Call_CreateConfigurationProfile_602033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ## 
  let valid = call_602045.validator(path, query, header, formData, body)
  let scheme = call_602045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602045.url(scheme.get, call_602045.host, call_602045.base,
                         call_602045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602045, url, valid)

proc call*(call_602046: Call_CreateConfigurationProfile_602033;
          ApplicationId: string; body: JsonNode): Recallable =
  ## createConfigurationProfile
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_602047 = newJObject()
  var body_602048 = newJObject()
  add(path_602047, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_602048 = body
  result = call_602046.call(path_602047, nil, nil, nil, body_602048)

var createConfigurationProfile* = Call_CreateConfigurationProfile_602033(
    name: "createConfigurationProfile", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_CreateConfigurationProfile_602034, base: "/",
    url: url_CreateConfigurationProfile_602035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationProfiles_602000 = ref object of OpenApiRestCall_601389
proc url_ListConfigurationProfiles_602002(protocol: Scheme; host: string;
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

proc validate_ListConfigurationProfiles_602001(path: JsonNode; query: JsonNode;
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
  var valid_602017 = path.getOrDefault("ApplicationId")
  valid_602017 = validateParameter(valid_602017, JString, required = true,
                                 default = nil)
  if valid_602017 != nil:
    section.add "ApplicationId", valid_602017
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
  var valid_602018 = query.getOrDefault("MaxResults")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "MaxResults", valid_602018
  var valid_602019 = query.getOrDefault("NextToken")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "NextToken", valid_602019
  var valid_602020 = query.getOrDefault("next_token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "next_token", valid_602020
  var valid_602021 = query.getOrDefault("max_results")
  valid_602021 = validateParameter(valid_602021, JInt, required = false, default = nil)
  if valid_602021 != nil:
    section.add "max_results", valid_602021
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
  var valid_602022 = header.getOrDefault("X-Amz-Signature")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Signature", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Content-Sha256", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Date")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Date", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Credential")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Credential", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Security-Token")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Security-Token", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Algorithm")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Algorithm", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-SignedHeaders", valid_602028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602029: Call_ListConfigurationProfiles_602000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the configuration profiles for an application.
  ## 
  let valid = call_602029.validator(path, query, header, formData, body)
  let scheme = call_602029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602029.url(scheme.get, call_602029.host, call_602029.base,
                         call_602029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602029, url, valid)

proc call*(call_602030: Call_ListConfigurationProfiles_602000;
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
  var path_602031 = newJObject()
  var query_602032 = newJObject()
  add(query_602032, "MaxResults", newJString(MaxResults))
  add(query_602032, "NextToken", newJString(NextToken))
  add(query_602032, "next_token", newJString(nextToken))
  add(path_602031, "ApplicationId", newJString(ApplicationId))
  add(query_602032, "max_results", newJInt(maxResults))
  result = call_602030.call(path_602031, query_602032, nil, nil, nil)

var listConfigurationProfiles* = Call_ListConfigurationProfiles_602000(
    name: "listConfigurationProfiles", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_ListConfigurationProfiles_602001, base: "/",
    url: url_ListConfigurationProfiles_602002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentStrategy_602066 = ref object of OpenApiRestCall_601389
proc url_CreateDeploymentStrategy_602068(protocol: Scheme; host: string;
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

proc validate_CreateDeploymentStrategy_602067(path: JsonNode; query: JsonNode;
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
  var valid_602069 = header.getOrDefault("X-Amz-Signature")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Signature", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Content-Sha256", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Date")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Date", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Credential")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Credential", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Security-Token")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Security-Token", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Algorithm")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Algorithm", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-SignedHeaders", valid_602075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602077: Call_CreateDeploymentStrategy_602066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_602077.validator(path, query, header, formData, body)
  let scheme = call_602077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602077.url(scheme.get, call_602077.host, call_602077.base,
                         call_602077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602077, url, valid)

proc call*(call_602078: Call_CreateDeploymentStrategy_602066; body: JsonNode): Recallable =
  ## createDeploymentStrategy
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   body: JObject (required)
  var body_602079 = newJObject()
  if body != nil:
    body_602079 = body
  result = call_602078.call(nil, nil, nil, nil, body_602079)

var createDeploymentStrategy* = Call_CreateDeploymentStrategy_602066(
    name: "createDeploymentStrategy", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_CreateDeploymentStrategy_602067, base: "/",
    url: url_CreateDeploymentStrategy_602068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentStrategies_602049 = ref object of OpenApiRestCall_601389
proc url_ListDeploymentStrategies_602051(protocol: Scheme; host: string;
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

proc validate_ListDeploymentStrategies_602050(path: JsonNode; query: JsonNode;
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
  var valid_602052 = query.getOrDefault("MaxResults")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "MaxResults", valid_602052
  var valid_602053 = query.getOrDefault("NextToken")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "NextToken", valid_602053
  var valid_602054 = query.getOrDefault("next_token")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "next_token", valid_602054
  var valid_602055 = query.getOrDefault("max_results")
  valid_602055 = validateParameter(valid_602055, JInt, required = false, default = nil)
  if valid_602055 != nil:
    section.add "max_results", valid_602055
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
  var valid_602056 = header.getOrDefault("X-Amz-Signature")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Signature", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Content-Sha256", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Date")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Date", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Credential")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Credential", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Security-Token")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Security-Token", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Algorithm")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Algorithm", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-SignedHeaders", valid_602062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602063: Call_ListDeploymentStrategies_602049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List deployment strategies.
  ## 
  let valid = call_602063.validator(path, query, header, formData, body)
  let scheme = call_602063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602063.url(scheme.get, call_602063.host, call_602063.base,
                         call_602063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602063, url, valid)

proc call*(call_602064: Call_ListDeploymentStrategies_602049;
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
  var query_602065 = newJObject()
  add(query_602065, "MaxResults", newJString(MaxResults))
  add(query_602065, "NextToken", newJString(NextToken))
  add(query_602065, "next_token", newJString(nextToken))
  add(query_602065, "max_results", newJInt(maxResults))
  result = call_602064.call(nil, query_602065, nil, nil, nil)

var listDeploymentStrategies* = Call_ListDeploymentStrategies_602049(
    name: "listDeploymentStrategies", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_ListDeploymentStrategies_602050, base: "/",
    url: url_ListDeploymentStrategies_602051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironment_602099 = ref object of OpenApiRestCall_601389
proc url_CreateEnvironment_602101(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEnvironment_602100(path: JsonNode; query: JsonNode;
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
  var valid_602102 = path.getOrDefault("ApplicationId")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = nil)
  if valid_602102 != nil:
    section.add "ApplicationId", valid_602102
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
  var valid_602103 = header.getOrDefault("X-Amz-Signature")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Signature", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Content-Sha256", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Date")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Date", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Credential")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Credential", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Security-Token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Security-Token", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Algorithm")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Algorithm", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-SignedHeaders", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602111: Call_CreateEnvironment_602099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ## 
  let valid = call_602111.validator(path, query, header, formData, body)
  let scheme = call_602111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602111.url(scheme.get, call_602111.host, call_602111.base,
                         call_602111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602111, url, valid)

proc call*(call_602112: Call_CreateEnvironment_602099; ApplicationId: string;
          body: JsonNode): Recallable =
  ## createEnvironment
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_602113 = newJObject()
  var body_602114 = newJObject()
  add(path_602113, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_602114 = body
  result = call_602112.call(path_602113, nil, nil, nil, body_602114)

var createEnvironment* = Call_CreateEnvironment_602099(name: "createEnvironment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_CreateEnvironment_602100, base: "/",
    url: url_CreateEnvironment_602101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_602080 = ref object of OpenApiRestCall_601389
proc url_ListEnvironments_602082(protocol: Scheme; host: string; base: string;
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

proc validate_ListEnvironments_602081(path: JsonNode; query: JsonNode;
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
  var valid_602083 = path.getOrDefault("ApplicationId")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "ApplicationId", valid_602083
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
  var valid_602084 = query.getOrDefault("MaxResults")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "MaxResults", valid_602084
  var valid_602085 = query.getOrDefault("NextToken")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "NextToken", valid_602085
  var valid_602086 = query.getOrDefault("next_token")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "next_token", valid_602086
  var valid_602087 = query.getOrDefault("max_results")
  valid_602087 = validateParameter(valid_602087, JInt, required = false, default = nil)
  if valid_602087 != nil:
    section.add "max_results", valid_602087
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
  var valid_602088 = header.getOrDefault("X-Amz-Signature")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Signature", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Content-Sha256", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Date")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Date", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Credential")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Credential", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Security-Token")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Security-Token", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Algorithm")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Algorithm", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-SignedHeaders", valid_602094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602095: Call_ListEnvironments_602080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the environments for an application.
  ## 
  let valid = call_602095.validator(path, query, header, formData, body)
  let scheme = call_602095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602095.url(scheme.get, call_602095.host, call_602095.base,
                         call_602095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602095, url, valid)

proc call*(call_602096: Call_ListEnvironments_602080; ApplicationId: string;
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
  var path_602097 = newJObject()
  var query_602098 = newJObject()
  add(query_602098, "MaxResults", newJString(MaxResults))
  add(query_602098, "NextToken", newJString(NextToken))
  add(query_602098, "next_token", newJString(nextToken))
  add(path_602097, "ApplicationId", newJString(ApplicationId))
  add(query_602098, "max_results", newJInt(maxResults))
  result = call_602096.call(path_602097, query_602098, nil, nil, nil)

var listEnvironments* = Call_ListEnvironments_602080(name: "listEnvironments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_ListEnvironments_602081, base: "/",
    url: url_ListEnvironments_602082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_602115 = ref object of OpenApiRestCall_601389
proc url_GetApplication_602117(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplication_602116(path: JsonNode; query: JsonNode;
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
  var valid_602118 = path.getOrDefault("ApplicationId")
  valid_602118 = validateParameter(valid_602118, JString, required = true,
                                 default = nil)
  if valid_602118 != nil:
    section.add "ApplicationId", valid_602118
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
  var valid_602119 = header.getOrDefault("X-Amz-Signature")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Signature", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Content-Sha256", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Date")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Date", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Credential")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Credential", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Security-Token")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Security-Token", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Algorithm")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Algorithm", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-SignedHeaders", valid_602125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_GetApplication_602115; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_GetApplication_602115; ApplicationId: string): Recallable =
  ## getApplication
  ## Retrieve information about an application.
  ##   ApplicationId: string (required)
  ##                : The ID of the application you want to get.
  var path_602128 = newJObject()
  add(path_602128, "ApplicationId", newJString(ApplicationId))
  result = call_602127.call(path_602128, nil, nil, nil, nil)

var getApplication* = Call_GetApplication_602115(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_GetApplication_602116,
    base: "/", url: url_GetApplication_602117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_602143 = ref object of OpenApiRestCall_601389
proc url_UpdateApplication_602145(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApplication_602144(path: JsonNode; query: JsonNode;
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
  var valid_602146 = path.getOrDefault("ApplicationId")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "ApplicationId", valid_602146
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
  var valid_602147 = header.getOrDefault("X-Amz-Signature")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Signature", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Content-Sha256", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Date")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Date", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Credential")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Credential", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Security-Token")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Security-Token", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Algorithm")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Algorithm", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-SignedHeaders", valid_602153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602155: Call_UpdateApplication_602143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_602155.validator(path, query, header, formData, body)
  let scheme = call_602155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602155.url(scheme.get, call_602155.host, call_602155.base,
                         call_602155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602155, url, valid)

proc call*(call_602156: Call_UpdateApplication_602143; ApplicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates an application.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_602157 = newJObject()
  var body_602158 = newJObject()
  add(path_602157, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_602158 = body
  result = call_602156.call(path_602157, nil, nil, nil, body_602158)

var updateApplication* = Call_UpdateApplication_602143(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_UpdateApplication_602144,
    base: "/", url: url_UpdateApplication_602145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_602129 = ref object of OpenApiRestCall_601389
proc url_DeleteApplication_602131(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApplication_602130(path: JsonNode; query: JsonNode;
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
  var valid_602132 = path.getOrDefault("ApplicationId")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "ApplicationId", valid_602132
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
  var valid_602133 = header.getOrDefault("X-Amz-Signature")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Signature", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Content-Sha256", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Date")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Date", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Credential")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Credential", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Security-Token")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Security-Token", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Algorithm")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Algorithm", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-SignedHeaders", valid_602139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602140: Call_DeleteApplication_602129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ## 
  let valid = call_602140.validator(path, query, header, formData, body)
  let scheme = call_602140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602140.url(scheme.get, call_602140.host, call_602140.base,
                         call_602140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602140, url, valid)

proc call*(call_602141: Call_DeleteApplication_602129; ApplicationId: string): Recallable =
  ## deleteApplication
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The ID of the application to delete.
  var path_602142 = newJObject()
  add(path_602142, "ApplicationId", newJString(ApplicationId))
  result = call_602141.call(path_602142, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_602129(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_DeleteApplication_602130,
    base: "/", url: url_DeleteApplication_602131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationProfile_602159 = ref object of OpenApiRestCall_601389
proc url_GetConfigurationProfile_602161(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfigurationProfile_602160(path: JsonNode; query: JsonNode;
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
  var valid_602162 = path.getOrDefault("ApplicationId")
  valid_602162 = validateParameter(valid_602162, JString, required = true,
                                 default = nil)
  if valid_602162 != nil:
    section.add "ApplicationId", valid_602162
  var valid_602163 = path.getOrDefault("ConfigurationProfileId")
  valid_602163 = validateParameter(valid_602163, JString, required = true,
                                 default = nil)
  if valid_602163 != nil:
    section.add "ConfigurationProfileId", valid_602163
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
  var valid_602164 = header.getOrDefault("X-Amz-Signature")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Signature", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Content-Sha256", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Date")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Date", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Credential")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Credential", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Security-Token")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Security-Token", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Algorithm")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Algorithm", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-SignedHeaders", valid_602170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602171: Call_GetConfigurationProfile_602159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration profile.
  ## 
  let valid = call_602171.validator(path, query, header, formData, body)
  let scheme = call_602171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602171.url(scheme.get, call_602171.host, call_602171.base,
                         call_602171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602171, url, valid)

proc call*(call_602172: Call_GetConfigurationProfile_602159; ApplicationId: string;
          ConfigurationProfileId: string): Recallable =
  ## getConfigurationProfile
  ## Retrieve information about a configuration profile.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the configuration profile you want to get.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to get.
  var path_602173 = newJObject()
  add(path_602173, "ApplicationId", newJString(ApplicationId))
  add(path_602173, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_602172.call(path_602173, nil, nil, nil, nil)

var getConfigurationProfile* = Call_GetConfigurationProfile_602159(
    name: "getConfigurationProfile", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_GetConfigurationProfile_602160, base: "/",
    url: url_GetConfigurationProfile_602161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationProfile_602189 = ref object of OpenApiRestCall_601389
proc url_UpdateConfigurationProfile_602191(protocol: Scheme; host: string;
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

proc validate_UpdateConfigurationProfile_602190(path: JsonNode; query: JsonNode;
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
  var valid_602192 = path.getOrDefault("ApplicationId")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = nil)
  if valid_602192 != nil:
    section.add "ApplicationId", valid_602192
  var valid_602193 = path.getOrDefault("ConfigurationProfileId")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "ConfigurationProfileId", valid_602193
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
  var valid_602194 = header.getOrDefault("X-Amz-Signature")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Signature", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Credential")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Credential", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Security-Token")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Security-Token", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Algorithm")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Algorithm", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-SignedHeaders", valid_602200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_UpdateConfigurationProfile_602189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a configuration profile.
  ## 
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_UpdateConfigurationProfile_602189;
          ApplicationId: string; body: JsonNode; ConfigurationProfileId: string): Recallable =
  ## updateConfigurationProfile
  ## Updates a configuration profile.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile.
  var path_602204 = newJObject()
  var body_602205 = newJObject()
  add(path_602204, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_602205 = body
  add(path_602204, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_602203.call(path_602204, nil, nil, nil, body_602205)

var updateConfigurationProfile* = Call_UpdateConfigurationProfile_602189(
    name: "updateConfigurationProfile", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_UpdateConfigurationProfile_602190, base: "/",
    url: url_UpdateConfigurationProfile_602191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationProfile_602174 = ref object of OpenApiRestCall_601389
proc url_DeleteConfigurationProfile_602176(protocol: Scheme; host: string;
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

proc validate_DeleteConfigurationProfile_602175(path: JsonNode; query: JsonNode;
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
  var valid_602177 = path.getOrDefault("ApplicationId")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = nil)
  if valid_602177 != nil:
    section.add "ApplicationId", valid_602177
  var valid_602178 = path.getOrDefault("ConfigurationProfileId")
  valid_602178 = validateParameter(valid_602178, JString, required = true,
                                 default = nil)
  if valid_602178 != nil:
    section.add "ConfigurationProfileId", valid_602178
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
  var valid_602179 = header.getOrDefault("X-Amz-Signature")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Signature", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Content-Sha256", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Date")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Date", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Credential")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Credential", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Security-Token")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Security-Token", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Algorithm")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Algorithm", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-SignedHeaders", valid_602185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_DeleteConfigurationProfile_602174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602186, url, valid)

proc call*(call_602187: Call_DeleteConfigurationProfile_602174;
          ApplicationId: string; ConfigurationProfileId: string): Recallable =
  ## deleteConfigurationProfile
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the configuration profile you want to delete.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to delete.
  var path_602188 = newJObject()
  add(path_602188, "ApplicationId", newJString(ApplicationId))
  add(path_602188, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  result = call_602187.call(path_602188, nil, nil, nil, nil)

var deleteConfigurationProfile* = Call_DeleteConfigurationProfile_602174(
    name: "deleteConfigurationProfile", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_DeleteConfigurationProfile_602175, base: "/",
    url: url_DeleteConfigurationProfile_602176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentStrategy_602206 = ref object of OpenApiRestCall_601389
proc url_DeleteDeploymentStrategy_602208(protocol: Scheme; host: string;
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

proc validate_DeleteDeploymentStrategy_602207(path: JsonNode; query: JsonNode;
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
  var valid_602209 = path.getOrDefault("DeploymentStrategyId")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = nil)
  if valid_602209 != nil:
    section.add "DeploymentStrategyId", valid_602209
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
  var valid_602210 = header.getOrDefault("X-Amz-Signature")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Signature", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Date")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Date", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Credential")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Credential", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Security-Token")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Security-Token", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Algorithm")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Algorithm", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602217: Call_DeleteDeploymentStrategy_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  let valid = call_602217.validator(path, query, header, formData, body)
  let scheme = call_602217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602217.url(scheme.get, call_602217.host, call_602217.base,
                         call_602217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602217, url, valid)

proc call*(call_602218: Call_DeleteDeploymentStrategy_602206;
          DeploymentStrategyId: string): Recallable =
  ## deleteDeploymentStrategy
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy you want to delete.
  var path_602219 = newJObject()
  add(path_602219, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_602218.call(path_602219, nil, nil, nil, nil)

var deleteDeploymentStrategy* = Call_DeleteDeploymentStrategy_602206(
    name: "deleteDeploymentStrategy", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com",
    route: "/deployementstrategies/{DeploymentStrategyId}",
    validator: validate_DeleteDeploymentStrategy_602207, base: "/",
    url: url_DeleteDeploymentStrategy_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnvironment_602220 = ref object of OpenApiRestCall_601389
proc url_GetEnvironment_602222(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnvironment_602221(path: JsonNode; query: JsonNode;
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
  var valid_602223 = path.getOrDefault("EnvironmentId")
  valid_602223 = validateParameter(valid_602223, JString, required = true,
                                 default = nil)
  if valid_602223 != nil:
    section.add "EnvironmentId", valid_602223
  var valid_602224 = path.getOrDefault("ApplicationId")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = nil)
  if valid_602224 != nil:
    section.add "ApplicationId", valid_602224
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
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602232: Call_GetEnvironment_602220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ## 
  let valid = call_602232.validator(path, query, header, formData, body)
  let scheme = call_602232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602232.url(scheme.get, call_602232.host, call_602232.base,
                         call_602232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602232, url, valid)

proc call*(call_602233: Call_GetEnvironment_602220; EnvironmentId: string;
          ApplicationId: string): Recallable =
  ## getEnvironment
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you wnat to get.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the environment you want to get.
  var path_602234 = newJObject()
  add(path_602234, "EnvironmentId", newJString(EnvironmentId))
  add(path_602234, "ApplicationId", newJString(ApplicationId))
  result = call_602233.call(path_602234, nil, nil, nil, nil)

var getEnvironment* = Call_GetEnvironment_602220(name: "getEnvironment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_GetEnvironment_602221, base: "/", url: url_GetEnvironment_602222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_602250 = ref object of OpenApiRestCall_601389
proc url_UpdateEnvironment_602252(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEnvironment_602251(path: JsonNode; query: JsonNode;
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
  var valid_602253 = path.getOrDefault("EnvironmentId")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = nil)
  if valid_602253 != nil:
    section.add "EnvironmentId", valid_602253
  var valid_602254 = path.getOrDefault("ApplicationId")
  valid_602254 = validateParameter(valid_602254, JString, required = true,
                                 default = nil)
  if valid_602254 != nil:
    section.add "ApplicationId", valid_602254
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
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_UpdateEnvironment_602250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an environment.
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_UpdateEnvironment_602250; EnvironmentId: string;
          ApplicationId: string; body: JsonNode): Recallable =
  ## updateEnvironment
  ## Updates an environment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_602265 = newJObject()
  var body_602266 = newJObject()
  add(path_602265, "EnvironmentId", newJString(EnvironmentId))
  add(path_602265, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_602266 = body
  result = call_602264.call(path_602265, nil, nil, nil, body_602266)

var updateEnvironment* = Call_UpdateEnvironment_602250(name: "updateEnvironment",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_UpdateEnvironment_602251, base: "/",
    url: url_UpdateEnvironment_602252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_602235 = ref object of OpenApiRestCall_601389
proc url_DeleteEnvironment_602237(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEnvironment_602236(path: JsonNode; query: JsonNode;
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
  var valid_602238 = path.getOrDefault("EnvironmentId")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = nil)
  if valid_602238 != nil:
    section.add "EnvironmentId", valid_602238
  var valid_602239 = path.getOrDefault("ApplicationId")
  valid_602239 = validateParameter(valid_602239, JString, required = true,
                                 default = nil)
  if valid_602239 != nil:
    section.add "ApplicationId", valid_602239
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
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602247: Call_DeleteEnvironment_602235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ## 
  let valid = call_602247.validator(path, query, header, formData, body)
  let scheme = call_602247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602247.url(scheme.get, call_602247.host, call_602247.base,
                         call_602247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602247, url, valid)

proc call*(call_602248: Call_DeleteEnvironment_602235; EnvironmentId: string;
          ApplicationId: string): Recallable =
  ## deleteEnvironment
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you want to delete.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the environment you want to delete.
  var path_602249 = newJObject()
  add(path_602249, "EnvironmentId", newJString(EnvironmentId))
  add(path_602249, "ApplicationId", newJString(ApplicationId))
  result = call_602248.call(path_602249, nil, nil, nil, nil)

var deleteEnvironment* = Call_DeleteEnvironment_602235(name: "deleteEnvironment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_DeleteEnvironment_602236, base: "/",
    url: url_DeleteEnvironment_602237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfiguration_602267 = ref object of OpenApiRestCall_601389
proc url_GetConfiguration_602269(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfiguration_602268(path: JsonNode; query: JsonNode;
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
  var valid_602270 = path.getOrDefault("Environment")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = nil)
  if valid_602270 != nil:
    section.add "Environment", valid_602270
  var valid_602271 = path.getOrDefault("Application")
  valid_602271 = validateParameter(valid_602271, JString, required = true,
                                 default = nil)
  if valid_602271 != nil:
    section.add "Application", valid_602271
  var valid_602272 = path.getOrDefault("Configuration")
  valid_602272 = validateParameter(valid_602272, JString, required = true,
                                 default = nil)
  if valid_602272 != nil:
    section.add "Configuration", valid_602272
  result.add "path", section
  ## parameters in `query` object:
  ##   client_id: JString (required)
  ##            : A unique ID to identify the client for the configuration. This ID enables AppConfig to deploy the configuration in intervals, as defined in the deployment strategy.
  ##   client_configuration_version: JString
  ##                               : The configuration version returned in the most recent GetConfiguration response.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `client_id` field"
  var valid_602273 = query.getOrDefault("client_id")
  valid_602273 = validateParameter(valid_602273, JString, required = true,
                                 default = nil)
  if valid_602273 != nil:
    section.add "client_id", valid_602273
  var valid_602274 = query.getOrDefault("client_configuration_version")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "client_configuration_version", valid_602274
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
  var valid_602275 = header.getOrDefault("X-Amz-Signature")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Signature", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Content-Sha256", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Date")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Date", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Credential")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Credential", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Security-Token")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Security-Token", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Algorithm")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Algorithm", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-SignedHeaders", valid_602281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602282: Call_GetConfiguration_602267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration.
  ## 
  let valid = call_602282.validator(path, query, header, formData, body)
  let scheme = call_602282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602282.url(scheme.get, call_602282.host, call_602282.base,
                         call_602282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602282, url, valid)

proc call*(call_602283: Call_GetConfiguration_602267; Environment: string;
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
  var path_602284 = newJObject()
  var query_602285 = newJObject()
  add(path_602284, "Environment", newJString(Environment))
  add(path_602284, "Application", newJString(Application))
  add(path_602284, "Configuration", newJString(Configuration))
  add(query_602285, "client_id", newJString(clientId))
  add(query_602285, "client_configuration_version",
      newJString(clientConfigurationVersion))
  result = call_602283.call(path_602284, query_602285, nil, nil, nil)

var getConfiguration* = Call_GetConfiguration_602267(name: "getConfiguration",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{Application}/environments/{Environment}/configurations/{Configuration}#client_id",
    validator: validate_GetConfiguration_602268, base: "/",
    url: url_GetConfiguration_602269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_602286 = ref object of OpenApiRestCall_601389
proc url_GetDeployment_602288(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_602287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602289 = path.getOrDefault("DeploymentNumber")
  valid_602289 = validateParameter(valid_602289, JInt, required = true, default = nil)
  if valid_602289 != nil:
    section.add "DeploymentNumber", valid_602289
  var valid_602290 = path.getOrDefault("EnvironmentId")
  valid_602290 = validateParameter(valid_602290, JString, required = true,
                                 default = nil)
  if valid_602290 != nil:
    section.add "EnvironmentId", valid_602290
  var valid_602291 = path.getOrDefault("ApplicationId")
  valid_602291 = validateParameter(valid_602291, JString, required = true,
                                 default = nil)
  if valid_602291 != nil:
    section.add "ApplicationId", valid_602291
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
  var valid_602292 = header.getOrDefault("X-Amz-Signature")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Signature", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Content-Sha256", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Credential")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Credential", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Security-Token")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Security-Token", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-SignedHeaders", valid_602298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602299: Call_GetDeployment_602286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a configuration deployment.
  ## 
  let valid = call_602299.validator(path, query, header, formData, body)
  let scheme = call_602299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602299.url(scheme.get, call_602299.host, call_602299.base,
                         call_602299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602299, url, valid)

proc call*(call_602300: Call_GetDeployment_602286; DeploymentNumber: int;
          EnvironmentId: string; ApplicationId: string): Recallable =
  ## getDeployment
  ## Retrieve information about a configuration deployment.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment that includes the deployment you want to get. 
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the deployment you want to get. 
  var path_602301 = newJObject()
  add(path_602301, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_602301, "EnvironmentId", newJString(EnvironmentId))
  add(path_602301, "ApplicationId", newJString(ApplicationId))
  result = call_602300.call(path_602301, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_602286(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_GetDeployment_602287, base: "/", url: url_GetDeployment_602288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_602302 = ref object of OpenApiRestCall_601389
proc url_StopDeployment_602304(protocol: Scheme; host: string; base: string;
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

proc validate_StopDeployment_602303(path: JsonNode; query: JsonNode;
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
  var valid_602305 = path.getOrDefault("DeploymentNumber")
  valid_602305 = validateParameter(valid_602305, JInt, required = true, default = nil)
  if valid_602305 != nil:
    section.add "DeploymentNumber", valid_602305
  var valid_602306 = path.getOrDefault("EnvironmentId")
  valid_602306 = validateParameter(valid_602306, JString, required = true,
                                 default = nil)
  if valid_602306 != nil:
    section.add "EnvironmentId", valid_602306
  var valid_602307 = path.getOrDefault("ApplicationId")
  valid_602307 = validateParameter(valid_602307, JString, required = true,
                                 default = nil)
  if valid_602307 != nil:
    section.add "ApplicationId", valid_602307
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
  var valid_602308 = header.getOrDefault("X-Amz-Signature")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Signature", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Content-Sha256", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Date")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Date", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Credential")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Credential", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Security-Token")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Security-Token", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Algorithm")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Algorithm", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-SignedHeaders", valid_602314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602315: Call_StopDeployment_602302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ## 
  let valid = call_602315.validator(path, query, header, formData, body)
  let scheme = call_602315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602315.url(scheme.get, call_602315.host, call_602315.base,
                         call_602315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602315, url, valid)

proc call*(call_602316: Call_StopDeployment_602302; DeploymentNumber: int;
          EnvironmentId: string; ApplicationId: string): Recallable =
  ## stopDeployment
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  var path_602317 = newJObject()
  add(path_602317, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_602317, "EnvironmentId", newJString(EnvironmentId))
  add(path_602317, "ApplicationId", newJString(ApplicationId))
  result = call_602316.call(path_602317, nil, nil, nil, nil)

var stopDeployment* = Call_StopDeployment_602302(name: "stopDeployment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_StopDeployment_602303, base: "/", url: url_StopDeployment_602304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStrategy_602318 = ref object of OpenApiRestCall_601389
proc url_GetDeploymentStrategy_602320(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeploymentStrategy_602319(path: JsonNode; query: JsonNode;
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
  var valid_602321 = path.getOrDefault("DeploymentStrategyId")
  valid_602321 = validateParameter(valid_602321, JString, required = true,
                                 default = nil)
  if valid_602321 != nil:
    section.add "DeploymentStrategyId", valid_602321
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
  var valid_602322 = header.getOrDefault("X-Amz-Signature")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Signature", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Content-Sha256", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Date")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Date", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Credential")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Credential", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Security-Token")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Security-Token", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Algorithm")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Algorithm", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-SignedHeaders", valid_602328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602329: Call_GetDeploymentStrategy_602318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_602329.validator(path, query, header, formData, body)
  let scheme = call_602329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602329.url(scheme.get, call_602329.host, call_602329.base,
                         call_602329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602329, url, valid)

proc call*(call_602330: Call_GetDeploymentStrategy_602318;
          DeploymentStrategyId: string): Recallable =
  ## getDeploymentStrategy
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy to get.
  var path_602331 = newJObject()
  add(path_602331, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_602330.call(path_602331, nil, nil, nil, nil)

var getDeploymentStrategy* = Call_GetDeploymentStrategy_602318(
    name: "getDeploymentStrategy", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_GetDeploymentStrategy_602319, base: "/",
    url: url_GetDeploymentStrategy_602320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentStrategy_602332 = ref object of OpenApiRestCall_601389
proc url_UpdateDeploymentStrategy_602334(protocol: Scheme; host: string;
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

proc validate_UpdateDeploymentStrategy_602333(path: JsonNode; query: JsonNode;
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
  var valid_602335 = path.getOrDefault("DeploymentStrategyId")
  valid_602335 = validateParameter(valid_602335, JString, required = true,
                                 default = nil)
  if valid_602335 != nil:
    section.add "DeploymentStrategyId", valid_602335
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
  var valid_602336 = header.getOrDefault("X-Amz-Signature")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Signature", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Content-Sha256", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Date")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Date", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Credential")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Credential", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Security-Token")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Security-Token", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Algorithm")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Algorithm", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-SignedHeaders", valid_602342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602344: Call_UpdateDeploymentStrategy_602332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a deployment strategy.
  ## 
  let valid = call_602344.validator(path, query, header, formData, body)
  let scheme = call_602344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602344.url(scheme.get, call_602344.host, call_602344.base,
                         call_602344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602344, url, valid)

proc call*(call_602345: Call_UpdateDeploymentStrategy_602332;
          DeploymentStrategyId: string; body: JsonNode): Recallable =
  ## updateDeploymentStrategy
  ## Updates a deployment strategy.
  ##   DeploymentStrategyId: string (required)
  ##                       : The deployment strategy ID.
  ##   body: JObject (required)
  var path_602346 = newJObject()
  var body_602347 = newJObject()
  add(path_602346, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  if body != nil:
    body_602347 = body
  result = call_602345.call(path_602346, nil, nil, nil, body_602347)

var updateDeploymentStrategy* = Call_UpdateDeploymentStrategy_602332(
    name: "updateDeploymentStrategy", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_UpdateDeploymentStrategy_602333, base: "/",
    url: url_UpdateDeploymentStrategy_602334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_602368 = ref object of OpenApiRestCall_601389
proc url_StartDeployment_602370(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_602369(path: JsonNode; query: JsonNode;
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
  var valid_602371 = path.getOrDefault("EnvironmentId")
  valid_602371 = validateParameter(valid_602371, JString, required = true,
                                 default = nil)
  if valid_602371 != nil:
    section.add "EnvironmentId", valid_602371
  var valid_602372 = path.getOrDefault("ApplicationId")
  valid_602372 = validateParameter(valid_602372, JString, required = true,
                                 default = nil)
  if valid_602372 != nil:
    section.add "ApplicationId", valid_602372
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
  var valid_602373 = header.getOrDefault("X-Amz-Signature")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Signature", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Content-Sha256", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Date")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Date", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Credential")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Credential", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Security-Token")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Security-Token", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Algorithm")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Algorithm", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-SignedHeaders", valid_602379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602381: Call_StartDeployment_602368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a deployment.
  ## 
  let valid = call_602381.validator(path, query, header, formData, body)
  let scheme = call_602381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602381.url(scheme.get, call_602381.host, call_602381.base,
                         call_602381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602381, url, valid)

proc call*(call_602382: Call_StartDeployment_602368; EnvironmentId: string;
          ApplicationId: string; body: JsonNode): Recallable =
  ## startDeployment
  ## Starts a deployment.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_602383 = newJObject()
  var body_602384 = newJObject()
  add(path_602383, "EnvironmentId", newJString(EnvironmentId))
  add(path_602383, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_602384 = body
  result = call_602382.call(path_602383, nil, nil, nil, body_602384)

var startDeployment* = Call_StartDeployment_602368(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_StartDeployment_602369, base: "/", url: url_StartDeployment_602370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_602348 = ref object of OpenApiRestCall_601389
proc url_ListDeployments_602350(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_602349(path: JsonNode; query: JsonNode;
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
  var valid_602351 = path.getOrDefault("EnvironmentId")
  valid_602351 = validateParameter(valid_602351, JString, required = true,
                                 default = nil)
  if valid_602351 != nil:
    section.add "EnvironmentId", valid_602351
  var valid_602352 = path.getOrDefault("ApplicationId")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = nil)
  if valid_602352 != nil:
    section.add "ApplicationId", valid_602352
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
  var valid_602353 = query.getOrDefault("MaxResults")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "MaxResults", valid_602353
  var valid_602354 = query.getOrDefault("NextToken")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "NextToken", valid_602354
  var valid_602355 = query.getOrDefault("next_token")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "next_token", valid_602355
  var valid_602356 = query.getOrDefault("max_results")
  valid_602356 = validateParameter(valid_602356, JInt, required = false, default = nil)
  if valid_602356 != nil:
    section.add "max_results", valid_602356
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
  var valid_602357 = header.getOrDefault("X-Amz-Signature")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Signature", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Content-Sha256", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Date")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Date", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Credential")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Credential", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Security-Token")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Security-Token", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Algorithm")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Algorithm", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-SignedHeaders", valid_602363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602364: Call_ListDeployments_602348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployments for an environment.
  ## 
  let valid = call_602364.validator(path, query, header, formData, body)
  let scheme = call_602364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602364.url(scheme.get, call_602364.host, call_602364.base,
                         call_602364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602364, url, valid)

proc call*(call_602365: Call_ListDeployments_602348; EnvironmentId: string;
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
  var path_602366 = newJObject()
  var query_602367 = newJObject()
  add(query_602367, "MaxResults", newJString(MaxResults))
  add(query_602367, "NextToken", newJString(NextToken))
  add(path_602366, "EnvironmentId", newJString(EnvironmentId))
  add(query_602367, "next_token", newJString(nextToken))
  add(path_602366, "ApplicationId", newJString(ApplicationId))
  add(query_602367, "max_results", newJInt(maxResults))
  result = call_602365.call(path_602366, query_602367, nil, nil, nil)

var listDeployments* = Call_ListDeployments_602348(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_ListDeployments_602349, base: "/", url: url_ListDeployments_602350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602399 = ref object of OpenApiRestCall_601389
proc url_TagResource_602401(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602402 = path.getOrDefault("ResourceArn")
  valid_602402 = validateParameter(valid_602402, JString, required = true,
                                 default = nil)
  if valid_602402 != nil:
    section.add "ResourceArn", valid_602402
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
  var valid_602403 = header.getOrDefault("X-Amz-Signature")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Signature", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Content-Sha256", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Date")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Date", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Credential")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Credential", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Security-Token")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Security-Token", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Algorithm")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Algorithm", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-SignedHeaders", valid_602409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602411: Call_TagResource_602399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ## 
  let valid = call_602411.validator(path, query, header, formData, body)
  let scheme = call_602411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602411.url(scheme.get, call_602411.host, call_602411.base,
                         call_602411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602411, url, valid)

proc call*(call_602412: Call_TagResource_602399; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to retrieve tags.
  ##   body: JObject (required)
  var path_602413 = newJObject()
  var body_602414 = newJObject()
  add(path_602413, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_602414 = body
  result = call_602412.call(path_602413, nil, nil, nil, body_602414)

var tagResource* = Call_TagResource_602399(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "appconfig.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_602400,
                                        base: "/", url: url_TagResource_602401,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602385 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602387(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602386(path: JsonNode; query: JsonNode;
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
  var valid_602388 = path.getOrDefault("ResourceArn")
  valid_602388 = validateParameter(valid_602388, JString, required = true,
                                 default = nil)
  if valid_602388 != nil:
    section.add "ResourceArn", valid_602388
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
  var valid_602389 = header.getOrDefault("X-Amz-Signature")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Signature", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Content-Sha256", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Date")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Date", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Credential")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Credential", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Security-Token")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Security-Token", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Algorithm")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Algorithm", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-SignedHeaders", valid_602395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602396: Call_ListTagsForResource_602385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the list of key-value tags assigned to the resource.
  ## 
  let valid = call_602396.validator(path, query, header, formData, body)
  let scheme = call_602396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602396.url(scheme.get, call_602396.host, call_602396.base,
                         call_602396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602396, url, valid)

proc call*(call_602397: Call_ListTagsForResource_602385; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves the list of key-value tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The resource ARN.
  var path_602398 = newJObject()
  add(path_602398, "ResourceArn", newJString(ResourceArn))
  result = call_602397.call(path_602398, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602385(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_602386, base: "/",
    url: url_ListTagsForResource_602387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602415 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602417(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602418 = path.getOrDefault("ResourceArn")
  valid_602418 = validateParameter(valid_602418, JString, required = true,
                                 default = nil)
  if valid_602418 != nil:
    section.add "ResourceArn", valid_602418
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602419 = query.getOrDefault("tagKeys")
  valid_602419 = validateParameter(valid_602419, JArray, required = true, default = nil)
  if valid_602419 != nil:
    section.add "tagKeys", valid_602419
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
  var valid_602420 = header.getOrDefault("X-Amz-Signature")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Signature", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Content-Sha256", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Date")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Date", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Credential")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Credential", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Security-Token")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Security-Token", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Algorithm")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Algorithm", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-SignedHeaders", valid_602426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602427: Call_UntagResource_602415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a tag key and value from an AppConfig resource.
  ## 
  let valid = call_602427.validator(path, query, header, formData, body)
  let scheme = call_602427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602427.url(scheme.get, call_602427.host, call_602427.base,
                         call_602427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602427, url, valid)

proc call*(call_602428: Call_UntagResource_602415; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes a tag key and value from an AppConfig resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to remove tags.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  var path_602429 = newJObject()
  var query_602430 = newJObject()
  add(path_602429, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_602430.add "tagKeys", tagKeys
  result = call_602428.call(path_602429, query_602430, nil, nil, nil)

var untagResource* = Call_UntagResource_602415(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_602416,
    base: "/", url: url_UntagResource_602417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidateConfiguration_602431 = ref object of OpenApiRestCall_601389
proc url_ValidateConfiguration_602433(protocol: Scheme; host: string; base: string;
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

proc validate_ValidateConfiguration_602432(path: JsonNode; query: JsonNode;
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
  var valid_602434 = path.getOrDefault("ApplicationId")
  valid_602434 = validateParameter(valid_602434, JString, required = true,
                                 default = nil)
  if valid_602434 != nil:
    section.add "ApplicationId", valid_602434
  var valid_602435 = path.getOrDefault("ConfigurationProfileId")
  valid_602435 = validateParameter(valid_602435, JString, required = true,
                                 default = nil)
  if valid_602435 != nil:
    section.add "ConfigurationProfileId", valid_602435
  result.add "path", section
  ## parameters in `query` object:
  ##   configuration_version: JString (required)
  ##                        : The version of the configuration to validate.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `configuration_version` field"
  var valid_602436 = query.getOrDefault("configuration_version")
  valid_602436 = validateParameter(valid_602436, JString, required = true,
                                 default = nil)
  if valid_602436 != nil:
    section.add "configuration_version", valid_602436
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
  var valid_602437 = header.getOrDefault("X-Amz-Signature")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Signature", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Content-Sha256", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Date")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Date", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Credential")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Credential", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Security-Token")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Security-Token", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Algorithm")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Algorithm", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-SignedHeaders", valid_602443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602444: Call_ValidateConfiguration_602431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uses the validators in a configuration profile to validate a configuration.
  ## 
  let valid = call_602444.validator(path, query, header, formData, body)
  let scheme = call_602444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602444.url(scheme.get, call_602444.host, call_602444.base,
                         call_602444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602444, url, valid)

proc call*(call_602445: Call_ValidateConfiguration_602431; ApplicationId: string;
          ConfigurationProfileId: string; configurationVersion: string): Recallable =
  ## validateConfiguration
  ## Uses the validators in a configuration profile to validate a configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   ConfigurationProfileId: string (required)
  ##                         : The configuration profile ID.
  ##   configurationVersion: string (required)
  ##                       : The version of the configuration to validate.
  var path_602446 = newJObject()
  var query_602447 = newJObject()
  add(path_602446, "ApplicationId", newJString(ApplicationId))
  add(path_602446, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(query_602447, "configuration_version", newJString(configurationVersion))
  result = call_602445.call(path_602446, query_602447, nil, nil, nil)

var validateConfiguration* = Call_ValidateConfiguration_602431(
    name: "validateConfiguration", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}/validators#configuration_version",
    validator: validate_ValidateConfiguration_602432, base: "/",
    url: url_ValidateConfiguration_602433, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
