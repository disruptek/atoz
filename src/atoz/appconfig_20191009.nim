
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateApplication_21626021 = ref object of OpenApiRestCall_21625435
proc url_CreateApplication_21626023(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_21626022(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626024 = header.getOrDefault("X-Amz-Date")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Date", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Security-Token", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
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

proc call*(call_21626032: Call_CreateApplication_21626021; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_CreateApplication_21626021; body: JsonNode): Recallable =
  ## createApplication
  ## An application in AppConfig is a logical unit of code that provides capabilities for your customers. For example, an application can be a microservice that runs on Amazon EC2 instances, a mobile application installed by your users, a serverless application using Amazon API Gateway and AWS Lambda, or any system you run on behalf of others.
  ##   body: JObject (required)
  var body_21626034 = newJObject()
  if body != nil:
    body_21626034 = body
  result = call_21626033.call(nil, nil, nil, nil, body_21626034)

var createApplication* = Call_CreateApplication_21626021(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_CreateApplication_21626022,
    base: "/", makeUrl: url_CreateApplication_21626023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListApplications_21625781(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_21625780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all applications in your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21625882 = query.getOrDefault("NextToken")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "NextToken", valid_21625882
  var valid_21625883 = query.getOrDefault("next_token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "next_token", valid_21625883
  var valid_21625884 = query.getOrDefault("max_results")
  valid_21625884 = validateParameter(valid_21625884, JInt, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "max_results", valid_21625884
  var valid_21625885 = query.getOrDefault("MaxResults")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "MaxResults", valid_21625885
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
  var valid_21625886 = header.getOrDefault("X-Amz-Date")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Date", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Security-Token", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Algorithm", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Signature")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Signature", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Credential")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Credential", valid_21625892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625917: Call_ListApplications_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List all applications in your AWS account.
  ## 
  let valid = call_21625917.validator(path, query, header, formData, body, _)
  let scheme = call_21625917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625917.makeUrl(scheme.get, call_21625917.host, call_21625917.base,
                               call_21625917.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625917, uri, valid, _)

proc call*(call_21625980: Call_ListApplications_21625779; NextToken: string = "";
          nextToken: string = ""; maxResults: int = 0; MaxResults: string = ""): Recallable =
  ## listApplications
  ## List all applications in your AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21625982 = newJObject()
  add(query_21625982, "NextToken", newJString(NextToken))
  add(query_21625982, "next_token", newJString(nextToken))
  add(query_21625982, "max_results", newJInt(maxResults))
  add(query_21625982, "MaxResults", newJString(MaxResults))
  result = call_21625980.call(nil, query_21625982, nil, nil, nil)

var listApplications* = Call_ListApplications_21625779(name: "listApplications",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications", validator: validate_ListApplications_21625780,
    base: "/", makeUrl: url_ListApplications_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationProfile_21626067 = ref object of OpenApiRestCall_21625435
proc url_CreateConfigurationProfile_21626069(protocol: Scheme; host: string;
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

proc validate_CreateConfigurationProfile_21626068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626070 = path.getOrDefault("ApplicationId")
  valid_21626070 = validateParameter(valid_21626070, JString, required = true,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "ApplicationId", valid_21626070
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
  var valid_21626071 = header.getOrDefault("X-Amz-Date")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Date", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Security-Token", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Algorithm", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Signature")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Signature", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Credential")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Credential", valid_21626077
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

proc call*(call_21626079: Call_CreateConfigurationProfile_21626067;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ## 
  let valid = call_21626079.validator(path, query, header, formData, body, _)
  let scheme = call_21626079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626079.makeUrl(scheme.get, call_21626079.host, call_21626079.base,
                               call_21626079.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626079, uri, valid, _)

proc call*(call_21626080: Call_CreateConfigurationProfile_21626067;
          ApplicationId: string; body: JsonNode): Recallable =
  ## createConfigurationProfile
  ## <p>Information that enables AppConfig to access the configuration source. Valid configuration sources include Systems Manager (SSM) documents and SSM Parameter Store parameters. A configuration profile includes the following information.</p> <ul> <li> <p>The Uri location of the configuration data.</p> </li> <li> <p>The AWS Identity and Access Management (IAM) role that provides access to the configuration data.</p> </li> <li> <p>A validator for the configuration data. Available validators include either a JSON Schema or an AWS Lambda function.</p> </li> </ul>
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_21626081 = newJObject()
  var body_21626082 = newJObject()
  add(path_21626081, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_21626082 = body
  result = call_21626080.call(path_21626081, nil, nil, nil, body_21626082)

var createConfigurationProfile* = Call_CreateConfigurationProfile_21626067(
    name: "createConfigurationProfile", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_CreateConfigurationProfile_21626068, base: "/",
    makeUrl: url_CreateConfigurationProfile_21626069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationProfiles_21626035 = ref object of OpenApiRestCall_21625435
proc url_ListConfigurationProfiles_21626037(protocol: Scheme; host: string;
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

proc validate_ListConfigurationProfiles_21626036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626051 = path.getOrDefault("ApplicationId")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "ApplicationId", valid_21626051
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626052 = query.getOrDefault("NextToken")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "NextToken", valid_21626052
  var valid_21626053 = query.getOrDefault("next_token")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "next_token", valid_21626053
  var valid_21626054 = query.getOrDefault("max_results")
  valid_21626054 = validateParameter(valid_21626054, JInt, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "max_results", valid_21626054
  var valid_21626055 = query.getOrDefault("MaxResults")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "MaxResults", valid_21626055
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
  var valid_21626056 = header.getOrDefault("X-Amz-Date")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Date", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Security-Token", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Algorithm", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Signature")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Signature", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Credential")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Credential", valid_21626062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626063: Call_ListConfigurationProfiles_21626035;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the configuration profiles for an application.
  ## 
  let valid = call_21626063.validator(path, query, header, formData, body, _)
  let scheme = call_21626063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626063.makeUrl(scheme.get, call_21626063.host, call_21626063.base,
                               call_21626063.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626063, uri, valid, _)

proc call*(call_21626064: Call_ListConfigurationProfiles_21626035;
          ApplicationId: string; NextToken: string = ""; nextToken: string = "";
          maxResults: int = 0; MaxResults: string = ""): Recallable =
  ## listConfigurationProfiles
  ## Lists the configuration profiles for an application.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626065 = newJObject()
  var query_21626066 = newJObject()
  add(query_21626066, "NextToken", newJString(NextToken))
  add(query_21626066, "next_token", newJString(nextToken))
  add(path_21626065, "ApplicationId", newJString(ApplicationId))
  add(query_21626066, "max_results", newJInt(maxResults))
  add(query_21626066, "MaxResults", newJString(MaxResults))
  result = call_21626064.call(path_21626065, query_21626066, nil, nil, nil)

var listConfigurationProfiles* = Call_ListConfigurationProfiles_21626035(
    name: "listConfigurationProfiles", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/configurationprofiles",
    validator: validate_ListConfigurationProfiles_21626036, base: "/",
    makeUrl: url_ListConfigurationProfiles_21626037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentStrategy_21626100 = ref object of OpenApiRestCall_21625435
proc url_CreateDeploymentStrategy_21626102(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentStrategy_21626101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626103 = header.getOrDefault("X-Amz-Date")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Date", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Security-Token", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Algorithm", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Signature")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Signature", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Credential")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Credential", valid_21626109
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

proc call*(call_21626111: Call_CreateDeploymentStrategy_21626100;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_21626111.validator(path, query, header, formData, body, _)
  let scheme = call_21626111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626111.makeUrl(scheme.get, call_21626111.host, call_21626111.base,
                               call_21626111.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626111, uri, valid, _)

proc call*(call_21626112: Call_CreateDeploymentStrategy_21626100; body: JsonNode): Recallable =
  ## createDeploymentStrategy
  ## A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   body: JObject (required)
  var body_21626113 = newJObject()
  if body != nil:
    body_21626113 = body
  result = call_21626112.call(nil, nil, nil, nil, body_21626113)

var createDeploymentStrategy* = Call_CreateDeploymentStrategy_21626100(
    name: "createDeploymentStrategy", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_CreateDeploymentStrategy_21626101, base: "/",
    makeUrl: url_CreateDeploymentStrategy_21626102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentStrategies_21626083 = ref object of OpenApiRestCall_21625435
proc url_ListDeploymentStrategies_21626085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentStrategies_21626084(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List deployment strategies.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626086 = query.getOrDefault("NextToken")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "NextToken", valid_21626086
  var valid_21626087 = query.getOrDefault("next_token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "next_token", valid_21626087
  var valid_21626088 = query.getOrDefault("max_results")
  valid_21626088 = validateParameter(valid_21626088, JInt, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "max_results", valid_21626088
  var valid_21626089 = query.getOrDefault("MaxResults")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "MaxResults", valid_21626089
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
  var valid_21626090 = header.getOrDefault("X-Amz-Date")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Date", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Security-Token", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Algorithm", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Signature")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Signature", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Credential")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Credential", valid_21626096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626097: Call_ListDeploymentStrategies_21626083;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List deployment strategies.
  ## 
  let valid = call_21626097.validator(path, query, header, formData, body, _)
  let scheme = call_21626097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626097.makeUrl(scheme.get, call_21626097.host, call_21626097.base,
                               call_21626097.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626097, uri, valid, _)

proc call*(call_21626098: Call_ListDeploymentStrategies_21626083;
          NextToken: string = ""; nextToken: string = ""; maxResults: int = 0;
          MaxResults: string = ""): Recallable =
  ## listDeploymentStrategies
  ## List deployment strategies.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626099 = newJObject()
  add(query_21626099, "NextToken", newJString(NextToken))
  add(query_21626099, "next_token", newJString(nextToken))
  add(query_21626099, "max_results", newJInt(maxResults))
  add(query_21626099, "MaxResults", newJString(MaxResults))
  result = call_21626098.call(nil, query_21626099, nil, nil, nil)

var listDeploymentStrategies* = Call_ListDeploymentStrategies_21626083(
    name: "listDeploymentStrategies", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/deploymentstrategies",
    validator: validate_ListDeploymentStrategies_21626084, base: "/",
    makeUrl: url_ListDeploymentStrategies_21626085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEnvironment_21626133 = ref object of OpenApiRestCall_21625435
proc url_CreateEnvironment_21626135(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEnvironment_21626134(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626136 = path.getOrDefault("ApplicationId")
  valid_21626136 = validateParameter(valid_21626136, JString, required = true,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "ApplicationId", valid_21626136
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
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Algorithm", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Signature")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Signature", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Credential")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Credential", valid_21626143
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

proc call*(call_21626145: Call_CreateEnvironment_21626133; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ## 
  let valid = call_21626145.validator(path, query, header, formData, body, _)
  let scheme = call_21626145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626145.makeUrl(scheme.get, call_21626145.host, call_21626145.base,
                               call_21626145.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626145, uri, valid, _)

proc call*(call_21626146: Call_CreateEnvironment_21626133; ApplicationId: string;
          body: JsonNode): Recallable =
  ## createEnvironment
  ## For each application, you define one or more environments. An environment is a logical deployment group of AppConfig targets, such as applications in a <code>Beta</code> or <code>Production</code> environment. You can also define environments for application subcomponents such as the <code>Web</code>, <code>Mobile</code> and <code>Back-end</code> components for your application. You can configure Amazon CloudWatch alarms for each environment. The system monitors alarms during a configuration deployment. If an alarm is triggered, the system rolls back the configuration.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_21626147 = newJObject()
  var body_21626148 = newJObject()
  add(path_21626147, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_21626148 = body
  result = call_21626146.call(path_21626147, nil, nil, nil, body_21626148)

var createEnvironment* = Call_CreateEnvironment_21626133(name: "createEnvironment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_CreateEnvironment_21626134, base: "/",
    makeUrl: url_CreateEnvironment_21626135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnvironments_21626114 = ref object of OpenApiRestCall_21625435
proc url_ListEnvironments_21626116(protocol: Scheme; host: string; base: string;
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

proc validate_ListEnvironments_21626115(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626117 = path.getOrDefault("ApplicationId")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "ApplicationId", valid_21626117
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626118 = query.getOrDefault("NextToken")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "NextToken", valid_21626118
  var valid_21626119 = query.getOrDefault("next_token")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "next_token", valid_21626119
  var valid_21626120 = query.getOrDefault("max_results")
  valid_21626120 = validateParameter(valid_21626120, JInt, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "max_results", valid_21626120
  var valid_21626121 = query.getOrDefault("MaxResults")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "MaxResults", valid_21626121
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Algorithm", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Signature")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Signature", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Credential")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Credential", valid_21626128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626129: Call_ListEnvironments_21626114; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the environments for an application.
  ## 
  let valid = call_21626129.validator(path, query, header, formData, body, _)
  let scheme = call_21626129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626129.makeUrl(scheme.get, call_21626129.host, call_21626129.base,
                               call_21626129.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626129, uri, valid, _)

proc call*(call_21626130: Call_ListEnvironments_21626114; ApplicationId: string;
          NextToken: string = ""; nextToken: string = ""; maxResults: int = 0;
          MaxResults: string = ""): Recallable =
  ## listEnvironments
  ## List the environments for an application.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626131 = newJObject()
  var query_21626132 = newJObject()
  add(query_21626132, "NextToken", newJString(NextToken))
  add(query_21626132, "next_token", newJString(nextToken))
  add(path_21626131, "ApplicationId", newJString(ApplicationId))
  add(query_21626132, "max_results", newJInt(maxResults))
  add(query_21626132, "MaxResults", newJString(MaxResults))
  result = call_21626130.call(path_21626131, query_21626132, nil, nil, nil)

var listEnvironments* = Call_ListEnvironments_21626114(name: "listEnvironments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments",
    validator: validate_ListEnvironments_21626115, base: "/",
    makeUrl: url_ListEnvironments_21626116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_21626149 = ref object of OpenApiRestCall_21625435
proc url_GetApplication_21626151(protocol: Scheme; host: string; base: string;
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

proc validate_GetApplication_21626150(path: JsonNode; query: JsonNode;
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
  var valid_21626152 = path.getOrDefault("ApplicationId")
  valid_21626152 = validateParameter(valid_21626152, JString, required = true,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "ApplicationId", valid_21626152
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
  var valid_21626153 = header.getOrDefault("X-Amz-Date")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Date", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Security-Token", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626160: Call_GetApplication_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_21626160.validator(path, query, header, formData, body, _)
  let scheme = call_21626160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626160.makeUrl(scheme.get, call_21626160.host, call_21626160.base,
                               call_21626160.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626160, uri, valid, _)

proc call*(call_21626161: Call_GetApplication_21626149; ApplicationId: string): Recallable =
  ## getApplication
  ## Retrieve information about an application.
  ##   ApplicationId: string (required)
  ##                : The ID of the application you want to get.
  var path_21626162 = newJObject()
  add(path_21626162, "ApplicationId", newJString(ApplicationId))
  result = call_21626161.call(path_21626162, nil, nil, nil, nil)

var getApplication* = Call_GetApplication_21626149(name: "getApplication",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_GetApplication_21626150,
    base: "/", makeUrl: url_GetApplication_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_21626177 = ref object of OpenApiRestCall_21625435
proc url_UpdateApplication_21626179(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateApplication_21626178(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626180 = path.getOrDefault("ApplicationId")
  valid_21626180 = validateParameter(valid_21626180, JString, required = true,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "ApplicationId", valid_21626180
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
  var valid_21626181 = header.getOrDefault("X-Amz-Date")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Date", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Security-Token", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Algorithm", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Signature")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Signature", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Credential")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Credential", valid_21626187
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

proc call*(call_21626189: Call_UpdateApplication_21626177; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an application.
  ## 
  let valid = call_21626189.validator(path, query, header, formData, body, _)
  let scheme = call_21626189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626189.makeUrl(scheme.get, call_21626189.host, call_21626189.base,
                               call_21626189.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626189, uri, valid, _)

proc call*(call_21626190: Call_UpdateApplication_21626177; ApplicationId: string;
          body: JsonNode): Recallable =
  ## updateApplication
  ## Updates an application.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_21626191 = newJObject()
  var body_21626192 = newJObject()
  add(path_21626191, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_21626192 = body
  result = call_21626190.call(path_21626191, nil, nil, nil, body_21626192)

var updateApplication* = Call_UpdateApplication_21626177(name: "updateApplication",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_UpdateApplication_21626178,
    base: "/", makeUrl: url_UpdateApplication_21626179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_21626163 = ref object of OpenApiRestCall_21625435
proc url_DeleteApplication_21626165(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteApplication_21626164(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626166 = path.getOrDefault("ApplicationId")
  valid_21626166 = validateParameter(valid_21626166, JString, required = true,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "ApplicationId", valid_21626166
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
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Algorithm", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Signature")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Signature", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Credential")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Credential", valid_21626173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626174: Call_DeleteApplication_21626163; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ## 
  let valid = call_21626174.validator(path, query, header, formData, body, _)
  let scheme = call_21626174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626174.makeUrl(scheme.get, call_21626174.host, call_21626174.base,
                               call_21626174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626174, uri, valid, _)

proc call*(call_21626175: Call_DeleteApplication_21626163; ApplicationId: string): Recallable =
  ## deleteApplication
  ## Delete an application. Deleting an application does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The ID of the application to delete.
  var path_21626176 = newJObject()
  add(path_21626176, "ApplicationId", newJString(ApplicationId))
  result = call_21626175.call(path_21626176, nil, nil, nil, nil)

var deleteApplication* = Call_DeleteApplication_21626163(name: "deleteApplication",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}", validator: validate_DeleteApplication_21626164,
    base: "/", makeUrl: url_DeleteApplication_21626165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationProfile_21626193 = ref object of OpenApiRestCall_21625435
proc url_GetConfigurationProfile_21626195(protocol: Scheme; host: string;
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

proc validate_GetConfigurationProfile_21626194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626196 = path.getOrDefault("ConfigurationProfileId")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "ConfigurationProfileId", valid_21626196
  var valid_21626197 = path.getOrDefault("ApplicationId")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "ApplicationId", valid_21626197
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
  var valid_21626198 = header.getOrDefault("X-Amz-Date")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Date", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Security-Token", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626205: Call_GetConfigurationProfile_21626193;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration profile.
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_GetConfigurationProfile_21626193;
          ConfigurationProfileId: string; ApplicationId: string): Recallable =
  ## getConfigurationProfile
  ## Retrieve information about a configuration profile.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to get.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the configuration profile you want to get.
  var path_21626207 = newJObject()
  add(path_21626207, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(path_21626207, "ApplicationId", newJString(ApplicationId))
  result = call_21626206.call(path_21626207, nil, nil, nil, nil)

var getConfigurationProfile* = Call_GetConfigurationProfile_21626193(
    name: "getConfigurationProfile", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_GetConfigurationProfile_21626194, base: "/",
    makeUrl: url_GetConfigurationProfile_21626195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationProfile_21626223 = ref object of OpenApiRestCall_21625435
proc url_UpdateConfigurationProfile_21626225(protocol: Scheme; host: string;
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

proc validate_UpdateConfigurationProfile_21626224(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626226 = path.getOrDefault("ConfigurationProfileId")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "ConfigurationProfileId", valid_21626226
  var valid_21626227 = path.getOrDefault("ApplicationId")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "ApplicationId", valid_21626227
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
  var valid_21626228 = header.getOrDefault("X-Amz-Date")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Date", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Security-Token", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
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

proc call*(call_21626236: Call_UpdateConfigurationProfile_21626223;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a configuration profile.
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_UpdateConfigurationProfile_21626223;
          ConfigurationProfileId: string; ApplicationId: string; body: JsonNode): Recallable =
  ## updateConfigurationProfile
  ## Updates a configuration profile.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  var path_21626238 = newJObject()
  var body_21626239 = newJObject()
  add(path_21626238, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(path_21626238, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_21626239 = body
  result = call_21626237.call(path_21626238, nil, nil, nil, body_21626239)

var updateConfigurationProfile* = Call_UpdateConfigurationProfile_21626223(
    name: "updateConfigurationProfile", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_UpdateConfigurationProfile_21626224, base: "/",
    makeUrl: url_UpdateConfigurationProfile_21626225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationProfile_21626208 = ref object of OpenApiRestCall_21625435
proc url_DeleteConfigurationProfile_21626210(protocol: Scheme; host: string;
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

proc validate_DeleteConfigurationProfile_21626209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626211 = path.getOrDefault("ConfigurationProfileId")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "ConfigurationProfileId", valid_21626211
  var valid_21626212 = path.getOrDefault("ApplicationId")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "ApplicationId", valid_21626212
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
  var valid_21626213 = header.getOrDefault("X-Amz-Date")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Date", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Security-Token", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626220: Call_DeleteConfigurationProfile_21626208;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ## 
  let valid = call_21626220.validator(path, query, header, formData, body, _)
  let scheme = call_21626220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626220.makeUrl(scheme.get, call_21626220.host, call_21626220.base,
                               call_21626220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626220, uri, valid, _)

proc call*(call_21626221: Call_DeleteConfigurationProfile_21626208;
          ConfigurationProfileId: string; ApplicationId: string): Recallable =
  ## deleteConfigurationProfile
  ## Delete a configuration profile. Deleting a configuration profile does not delete a configuration from a host.
  ##   ConfigurationProfileId: string (required)
  ##                         : The ID of the configuration profile you want to delete.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the configuration profile you want to delete.
  var path_21626222 = newJObject()
  add(path_21626222, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(path_21626222, "ApplicationId", newJString(ApplicationId))
  result = call_21626221.call(path_21626222, nil, nil, nil, nil)

var deleteConfigurationProfile* = Call_DeleteConfigurationProfile_21626208(
    name: "deleteConfigurationProfile", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}",
    validator: validate_DeleteConfigurationProfile_21626209, base: "/",
    makeUrl: url_DeleteConfigurationProfile_21626210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentStrategy_21626240 = ref object of OpenApiRestCall_21625435
proc url_DeleteDeploymentStrategy_21626242(protocol: Scheme; host: string;
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

proc validate_DeleteDeploymentStrategy_21626241(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The ID of the deployment strategy you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_21626243 = path.getOrDefault("DeploymentStrategyId")
  valid_21626243 = validateParameter(valid_21626243, JString, required = true,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "DeploymentStrategyId", valid_21626243
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
  var valid_21626244 = header.getOrDefault("X-Amz-Date")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Date", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Security-Token", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Algorithm", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Signature")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Signature", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Credential")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Credential", valid_21626250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626251: Call_DeleteDeploymentStrategy_21626240;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_DeleteDeploymentStrategy_21626240;
          DeploymentStrategyId: string): Recallable =
  ## deleteDeploymentStrategy
  ## Delete a deployment strategy. Deleting a deployment strategy does not delete a configuration from a host.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy you want to delete.
  var path_21626253 = newJObject()
  add(path_21626253, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_21626252.call(path_21626253, nil, nil, nil, nil)

var deleteDeploymentStrategy* = Call_DeleteDeploymentStrategy_21626240(
    name: "deleteDeploymentStrategy", meth: HttpMethod.HttpDelete,
    host: "appconfig.amazonaws.com",
    route: "/deployementstrategies/{DeploymentStrategyId}",
    validator: validate_DeleteDeploymentStrategy_21626241, base: "/",
    makeUrl: url_DeleteDeploymentStrategy_21626242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnvironment_21626254 = ref object of OpenApiRestCall_21625435
proc url_GetEnvironment_21626256(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnvironment_21626255(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString (required)
  ##                : The ID of the environment you wnat to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_21626257 = path.getOrDefault("ApplicationId")
  valid_21626257 = validateParameter(valid_21626257, JString, required = true,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "ApplicationId", valid_21626257
  var valid_21626258 = path.getOrDefault("EnvironmentId")
  valid_21626258 = validateParameter(valid_21626258, JString, required = true,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "EnvironmentId", valid_21626258
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
  var valid_21626259 = header.getOrDefault("X-Amz-Date")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Date", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Security-Token", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Algorithm", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Signature")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Signature", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Credential")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Credential", valid_21626265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_GetEnvironment_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_GetEnvironment_21626254; ApplicationId: string;
          EnvironmentId: string): Recallable =
  ## getEnvironment
  ## Retrieve information about an environment. An environment is a logical deployment group of AppConfig applications, such as applications in a <code>Production</code> environment or in an <code>EU_Region</code> environment. Each configuration deployment targets an environment. You can enable one or more Amazon CloudWatch alarms for an environment. If an alarm is triggered during a deployment, AppConfig roles back the configuration.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the environment you want to get.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you wnat to get.
  var path_21626268 = newJObject()
  add(path_21626268, "ApplicationId", newJString(ApplicationId))
  add(path_21626268, "EnvironmentId", newJString(EnvironmentId))
  result = call_21626267.call(path_21626268, nil, nil, nil, nil)

var getEnvironment* = Call_GetEnvironment_21626254(name: "getEnvironment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_GetEnvironment_21626255, base: "/",
    makeUrl: url_GetEnvironment_21626256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEnvironment_21626284 = ref object of OpenApiRestCall_21625435
proc url_UpdateEnvironment_21626286(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEnvironment_21626285(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626287 = path.getOrDefault("ApplicationId")
  valid_21626287 = validateParameter(valid_21626287, JString, required = true,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "ApplicationId", valid_21626287
  var valid_21626288 = path.getOrDefault("EnvironmentId")
  valid_21626288 = validateParameter(valid_21626288, JString, required = true,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "EnvironmentId", valid_21626288
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
  var valid_21626289 = header.getOrDefault("X-Amz-Date")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Date", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Security-Token", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Algorithm", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Signature")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Signature", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Credential")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Credential", valid_21626295
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

proc call*(call_21626297: Call_UpdateEnvironment_21626284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an environment.
  ## 
  let valid = call_21626297.validator(path, query, header, formData, body, _)
  let scheme = call_21626297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626297.makeUrl(scheme.get, call_21626297.host, call_21626297.base,
                               call_21626297.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626297, uri, valid, _)

proc call*(call_21626298: Call_UpdateEnvironment_21626284; ApplicationId: string;
          body: JsonNode; EnvironmentId: string): Recallable =
  ## updateEnvironment
  ## Updates an environment.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_21626299 = newJObject()
  var body_21626300 = newJObject()
  add(path_21626299, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_21626300 = body
  add(path_21626299, "EnvironmentId", newJString(EnvironmentId))
  result = call_21626298.call(path_21626299, nil, nil, nil, body_21626300)

var updateEnvironment* = Call_UpdateEnvironment_21626284(name: "updateEnvironment",
    meth: HttpMethod.HttpPatch, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_UpdateEnvironment_21626285, base: "/",
    makeUrl: url_UpdateEnvironment_21626286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEnvironment_21626269 = ref object of OpenApiRestCall_21625435
proc url_DeleteEnvironment_21626271(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEnvironment_21626270(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626272 = path.getOrDefault("ApplicationId")
  valid_21626272 = validateParameter(valid_21626272, JString, required = true,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "ApplicationId", valid_21626272
  var valid_21626273 = path.getOrDefault("EnvironmentId")
  valid_21626273 = validateParameter(valid_21626273, JString, required = true,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "EnvironmentId", valid_21626273
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
  var valid_21626274 = header.getOrDefault("X-Amz-Date")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Date", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Security-Token", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Algorithm", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Signature")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Signature", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Credential")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Credential", valid_21626280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626281: Call_DeleteEnvironment_21626269; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_DeleteEnvironment_21626269; ApplicationId: string;
          EnvironmentId: string): Recallable =
  ## deleteEnvironment
  ## Delete an environment. Deleting an environment does not delete a configuration from a host.
  ##   ApplicationId: string (required)
  ##                : The application ID that includes the environment you want to delete.
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment you want to delete.
  var path_21626283 = newJObject()
  add(path_21626283, "ApplicationId", newJString(ApplicationId))
  add(path_21626283, "EnvironmentId", newJString(EnvironmentId))
  result = call_21626282.call(path_21626283, nil, nil, nil, nil)

var deleteEnvironment* = Call_DeleteEnvironment_21626269(name: "deleteEnvironment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/applications/{ApplicationId}/environments/{EnvironmentId}",
    validator: validate_DeleteEnvironment_21626270, base: "/",
    makeUrl: url_DeleteEnvironment_21626271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfiguration_21626301 = ref object of OpenApiRestCall_21625435
proc url_GetConfiguration_21626303(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfiguration_21626302(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626304 = path.getOrDefault("Configuration")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "Configuration", valid_21626304
  var valid_21626305 = path.getOrDefault("Application")
  valid_21626305 = validateParameter(valid_21626305, JString, required = true,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "Application", valid_21626305
  var valid_21626306 = path.getOrDefault("Environment")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "Environment", valid_21626306
  result.add "path", section
  ## parameters in `query` object:
  ##   client_id: JString (required)
  ##            : A unique ID to identify the client for the configuration. This ID enables AppConfig to deploy the configuration in intervals, as defined in the deployment strategy.
  ##   client_configuration_version: JString
  ##                               : The configuration version returned in the most recent GetConfiguration response.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `client_id` field"
  var valid_21626307 = query.getOrDefault("client_id")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "client_id", valid_21626307
  var valid_21626308 = query.getOrDefault("client_configuration_version")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "client_configuration_version", valid_21626308
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
  var valid_21626309 = header.getOrDefault("X-Amz-Date")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Date", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Security-Token", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Algorithm", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Signature")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Signature", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Credential")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Credential", valid_21626315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626316: Call_GetConfiguration_21626301; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration.
  ## 
  let valid = call_21626316.validator(path, query, header, formData, body, _)
  let scheme = call_21626316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626316.makeUrl(scheme.get, call_21626316.host, call_21626316.base,
                               call_21626316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626316, uri, valid, _)

proc call*(call_21626317: Call_GetConfiguration_21626301; clientId: string;
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
  var path_21626318 = newJObject()
  var query_21626319 = newJObject()
  add(query_21626319, "client_id", newJString(clientId))
  add(path_21626318, "Configuration", newJString(Configuration))
  add(path_21626318, "Application", newJString(Application))
  add(path_21626318, "Environment", newJString(Environment))
  add(query_21626319, "client_configuration_version",
      newJString(clientConfigurationVersion))
  result = call_21626317.call(path_21626318, query_21626319, nil, nil, nil)

var getConfiguration* = Call_GetConfiguration_21626301(name: "getConfiguration",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{Application}/environments/{Environment}/configurations/{Configuration}#client_id",
    validator: validate_GetConfiguration_21626302, base: "/",
    makeUrl: url_GetConfiguration_21626303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_21626320 = ref object of OpenApiRestCall_21625435
proc url_GetDeployment_21626322(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeployment_21626321(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626323 = path.getOrDefault("DeploymentNumber")
  valid_21626323 = validateParameter(valid_21626323, JInt, required = true,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "DeploymentNumber", valid_21626323
  var valid_21626324 = path.getOrDefault("ApplicationId")
  valid_21626324 = validateParameter(valid_21626324, JString, required = true,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "ApplicationId", valid_21626324
  var valid_21626325 = path.getOrDefault("EnvironmentId")
  valid_21626325 = validateParameter(valid_21626325, JString, required = true,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "EnvironmentId", valid_21626325
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
  var valid_21626326 = header.getOrDefault("X-Amz-Date")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Date", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Security-Token", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Algorithm", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Signature")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Signature", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Credential")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Credential", valid_21626332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626333: Call_GetDeployment_21626320; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a configuration deployment.
  ## 
  let valid = call_21626333.validator(path, query, header, formData, body, _)
  let scheme = call_21626333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626333.makeUrl(scheme.get, call_21626333.host, call_21626333.base,
                               call_21626333.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626333, uri, valid, _)

proc call*(call_21626334: Call_GetDeployment_21626320; DeploymentNumber: int;
          ApplicationId: string; EnvironmentId: string): Recallable =
  ## getDeployment
  ## Retrieve information about a configuration deployment.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   ApplicationId: string (required)
  ##                : The ID of the application that includes the deployment you want to get. 
  ##   EnvironmentId: string (required)
  ##                : The ID of the environment that includes the deployment you want to get. 
  var path_21626335 = newJObject()
  add(path_21626335, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_21626335, "ApplicationId", newJString(ApplicationId))
  add(path_21626335, "EnvironmentId", newJString(EnvironmentId))
  result = call_21626334.call(path_21626335, nil, nil, nil, nil)

var getDeployment* = Call_GetDeployment_21626320(name: "getDeployment",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_GetDeployment_21626321, base: "/",
    makeUrl: url_GetDeployment_21626322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_21626336 = ref object of OpenApiRestCall_21625435
proc url_StopDeployment_21626338(protocol: Scheme; host: string; base: string;
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

proc validate_StopDeployment_21626337(path: JsonNode; query: JsonNode;
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
  ##   ApplicationId: JString (required)
  ##                : The application ID.
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DeploymentNumber` field"
  var valid_21626339 = path.getOrDefault("DeploymentNumber")
  valid_21626339 = validateParameter(valid_21626339, JInt, required = true,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "DeploymentNumber", valid_21626339
  var valid_21626340 = path.getOrDefault("ApplicationId")
  valid_21626340 = validateParameter(valid_21626340, JString, required = true,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "ApplicationId", valid_21626340
  var valid_21626341 = path.getOrDefault("EnvironmentId")
  valid_21626341 = validateParameter(valid_21626341, JString, required = true,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "EnvironmentId", valid_21626341
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
  var valid_21626342 = header.getOrDefault("X-Amz-Date")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Date", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Security-Token", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Algorithm", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Signature")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Signature", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Credential")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Credential", valid_21626348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626349: Call_StopDeployment_21626336; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ## 
  let valid = call_21626349.validator(path, query, header, formData, body, _)
  let scheme = call_21626349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626349.makeUrl(scheme.get, call_21626349.host, call_21626349.base,
                               call_21626349.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626349, uri, valid, _)

proc call*(call_21626350: Call_StopDeployment_21626336; DeploymentNumber: int;
          ApplicationId: string; EnvironmentId: string): Recallable =
  ## stopDeployment
  ## Stops a deployment. This API action works only on deployments that have a status of <code>DEPLOYING</code>. This action moves the deployment to a status of <code>ROLLED_BACK</code>.
  ##   DeploymentNumber: int (required)
  ##                   : The sequence number of the deployment.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_21626351 = newJObject()
  add(path_21626351, "DeploymentNumber", newJInt(DeploymentNumber))
  add(path_21626351, "ApplicationId", newJString(ApplicationId))
  add(path_21626351, "EnvironmentId", newJString(EnvironmentId))
  result = call_21626350.call(path_21626351, nil, nil, nil, nil)

var stopDeployment* = Call_StopDeployment_21626336(name: "stopDeployment",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments/{DeploymentNumber}",
    validator: validate_StopDeployment_21626337, base: "/",
    makeUrl: url_StopDeployment_21626338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentStrategy_21626352 = ref object of OpenApiRestCall_21625435
proc url_GetDeploymentStrategy_21626354(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetDeploymentStrategy_21626353(path: JsonNode; query: JsonNode;
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
  var valid_21626355 = path.getOrDefault("DeploymentStrategyId")
  valid_21626355 = validateParameter(valid_21626355, JString, required = true,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "DeploymentStrategyId", valid_21626355
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
  var valid_21626356 = header.getOrDefault("X-Amz-Date")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Date", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Security-Token", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Algorithm", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Signature")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Signature", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Credential")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Credential", valid_21626362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626363: Call_GetDeploymentStrategy_21626352;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ## 
  let valid = call_21626363.validator(path, query, header, formData, body, _)
  let scheme = call_21626363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626363.makeUrl(scheme.get, call_21626363.host, call_21626363.base,
                               call_21626363.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626363, uri, valid, _)

proc call*(call_21626364: Call_GetDeploymentStrategy_21626352;
          DeploymentStrategyId: string): Recallable =
  ## getDeploymentStrategy
  ## Retrieve information about a deployment strategy. A deployment strategy defines important criteria for rolling out your configuration to the designated targets. A deployment strategy includes: the overall duration required, a percentage of targets to receive the deployment during each interval, an algorithm that defines how percentage grows, and bake time.
  ##   DeploymentStrategyId: string (required)
  ##                       : The ID of the deployment strategy to get.
  var path_21626365 = newJObject()
  add(path_21626365, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  result = call_21626364.call(path_21626365, nil, nil, nil, nil)

var getDeploymentStrategy* = Call_GetDeploymentStrategy_21626352(
    name: "getDeploymentStrategy", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_GetDeploymentStrategy_21626353, base: "/",
    makeUrl: url_GetDeploymentStrategy_21626354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentStrategy_21626366 = ref object of OpenApiRestCall_21625435
proc url_UpdateDeploymentStrategy_21626368(protocol: Scheme; host: string;
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

proc validate_UpdateDeploymentStrategy_21626367(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a deployment strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DeploymentStrategyId: JString (required)
  ##                       : The deployment strategy ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DeploymentStrategyId` field"
  var valid_21626369 = path.getOrDefault("DeploymentStrategyId")
  valid_21626369 = validateParameter(valid_21626369, JString, required = true,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "DeploymentStrategyId", valid_21626369
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
  var valid_21626370 = header.getOrDefault("X-Amz-Date")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Date", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Security-Token", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Algorithm", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Signature")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Signature", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Credential")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Credential", valid_21626376
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

proc call*(call_21626378: Call_UpdateDeploymentStrategy_21626366;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a deployment strategy.
  ## 
  let valid = call_21626378.validator(path, query, header, formData, body, _)
  let scheme = call_21626378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626378.makeUrl(scheme.get, call_21626378.host, call_21626378.base,
                               call_21626378.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626378, uri, valid, _)

proc call*(call_21626379: Call_UpdateDeploymentStrategy_21626366;
          DeploymentStrategyId: string; body: JsonNode): Recallable =
  ## updateDeploymentStrategy
  ## Updates a deployment strategy.
  ##   DeploymentStrategyId: string (required)
  ##                       : The deployment strategy ID.
  ##   body: JObject (required)
  var path_21626380 = newJObject()
  var body_21626381 = newJObject()
  add(path_21626380, "DeploymentStrategyId", newJString(DeploymentStrategyId))
  if body != nil:
    body_21626381 = body
  result = call_21626379.call(path_21626380, nil, nil, nil, body_21626381)

var updateDeploymentStrategy* = Call_UpdateDeploymentStrategy_21626366(
    name: "updateDeploymentStrategy", meth: HttpMethod.HttpPatch,
    host: "appconfig.amazonaws.com",
    route: "/deploymentstrategies/{DeploymentStrategyId}",
    validator: validate_UpdateDeploymentStrategy_21626367, base: "/",
    makeUrl: url_UpdateDeploymentStrategy_21626368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDeployment_21626402 = ref object of OpenApiRestCall_21625435
proc url_StartDeployment_21626404(protocol: Scheme; host: string; base: string;
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

proc validate_StartDeployment_21626403(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_21626405 = path.getOrDefault("ApplicationId")
  valid_21626405 = validateParameter(valid_21626405, JString, required = true,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "ApplicationId", valid_21626405
  var valid_21626406 = path.getOrDefault("EnvironmentId")
  valid_21626406 = validateParameter(valid_21626406, JString, required = true,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "EnvironmentId", valid_21626406
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
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Algorithm", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Signature")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Signature", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Credential")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Credential", valid_21626413
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

proc call*(call_21626415: Call_StartDeployment_21626402; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a deployment.
  ## 
  let valid = call_21626415.validator(path, query, header, formData, body, _)
  let scheme = call_21626415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626415.makeUrl(scheme.get, call_21626415.host, call_21626415.base,
                               call_21626415.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626415, uri, valid, _)

proc call*(call_21626416: Call_StartDeployment_21626402; ApplicationId: string;
          body: JsonNode; EnvironmentId: string): Recallable =
  ## startDeployment
  ## Starts a deployment.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   body: JObject (required)
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_21626417 = newJObject()
  var body_21626418 = newJObject()
  add(path_21626417, "ApplicationId", newJString(ApplicationId))
  if body != nil:
    body_21626418 = body
  add(path_21626417, "EnvironmentId", newJString(EnvironmentId))
  result = call_21626416.call(path_21626417, nil, nil, nil, body_21626418)

var startDeployment* = Call_StartDeployment_21626402(name: "startDeployment",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_StartDeployment_21626403, base: "/",
    makeUrl: url_StartDeployment_21626404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_21626382 = ref object of OpenApiRestCall_21625435
proc url_ListDeployments_21626384(protocol: Scheme; host: string; base: string;
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

proc validate_ListDeployments_21626383(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString (required)
  ##                : The environment ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ApplicationId` field"
  var valid_21626385 = path.getOrDefault("ApplicationId")
  valid_21626385 = validateParameter(valid_21626385, JString, required = true,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "ApplicationId", valid_21626385
  var valid_21626386 = path.getOrDefault("EnvironmentId")
  valid_21626386 = validateParameter(valid_21626386, JString, required = true,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "EnvironmentId", valid_21626386
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A token to start the list. Use this token to get the next set of results.
  ##   max_results: JInt
  ##              : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626387 = query.getOrDefault("NextToken")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "NextToken", valid_21626387
  var valid_21626388 = query.getOrDefault("next_token")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "next_token", valid_21626388
  var valid_21626389 = query.getOrDefault("max_results")
  valid_21626389 = validateParameter(valid_21626389, JInt, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "max_results", valid_21626389
  var valid_21626390 = query.getOrDefault("MaxResults")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "MaxResults", valid_21626390
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
  var valid_21626391 = header.getOrDefault("X-Amz-Date")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Date", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Security-Token", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626398: Call_ListDeployments_21626382; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the deployments for an environment.
  ## 
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_ListDeployments_21626382; ApplicationId: string;
          EnvironmentId: string; NextToken: string = ""; nextToken: string = "";
          maxResults: int = 0; MaxResults: string = ""): Recallable =
  ## listDeployments
  ## Lists the deployments for an environment.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A token to start the list. Use this token to get the next set of results.
  ##   ApplicationId: string (required)
  ##                : The application ID.
  ##   maxResults: int
  ##             : The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   EnvironmentId: string (required)
  ##                : The environment ID.
  var path_21626400 = newJObject()
  var query_21626401 = newJObject()
  add(query_21626401, "NextToken", newJString(NextToken))
  add(query_21626401, "next_token", newJString(nextToken))
  add(path_21626400, "ApplicationId", newJString(ApplicationId))
  add(query_21626401, "max_results", newJInt(maxResults))
  add(query_21626401, "MaxResults", newJString(MaxResults))
  add(path_21626400, "EnvironmentId", newJString(EnvironmentId))
  result = call_21626399.call(path_21626400, query_21626401, nil, nil, nil)

var listDeployments* = Call_ListDeployments_21626382(name: "listDeployments",
    meth: HttpMethod.HttpGet, host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/environments/{EnvironmentId}/deployments",
    validator: validate_ListDeployments_21626383, base: "/",
    makeUrl: url_ListDeployments_21626384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626433 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626435(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626434(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626436 = path.getOrDefault("ResourceArn")
  valid_21626436 = validateParameter(valid_21626436, JString, required = true,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "ResourceArn", valid_21626436
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
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Algorithm", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Signature")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Signature", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Credential")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Credential", valid_21626443
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

proc call*(call_21626445: Call_TagResource_21626433; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ## 
  let valid = call_21626445.validator(path, query, header, formData, body, _)
  let scheme = call_21626445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626445.makeUrl(scheme.get, call_21626445.host, call_21626445.base,
                               call_21626445.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626445, uri, valid, _)

proc call*(call_21626446: Call_TagResource_21626433; ResourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ## Metadata to assign to an AppConfig resource. Tags help organize and categorize your AppConfig resources. Each tag consists of a key and an optional value, both of which you define. You can specify a maximum of 50 tags for a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to retrieve tags.
  ##   body: JObject (required)
  var path_21626447 = newJObject()
  var body_21626448 = newJObject()
  add(path_21626447, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_21626448 = body
  result = call_21626446.call(path_21626447, nil, nil, nil, body_21626448)

var tagResource* = Call_TagResource_21626433(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}", validator: validate_TagResource_21626434,
    base: "/", makeUrl: url_TagResource_21626435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626419 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626421(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626420(path: JsonNode; query: JsonNode;
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
  var valid_21626422 = path.getOrDefault("ResourceArn")
  valid_21626422 = validateParameter(valid_21626422, JString, required = true,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "ResourceArn", valid_21626422
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
  var valid_21626423 = header.getOrDefault("X-Amz-Date")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Date", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Security-Token", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626430: Call_ListTagsForResource_21626419; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the list of key-value tags assigned to the resource.
  ## 
  let valid = call_21626430.validator(path, query, header, formData, body, _)
  let scheme = call_21626430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626430.makeUrl(scheme.get, call_21626430.host, call_21626430.base,
                               call_21626430.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626430, uri, valid, _)

proc call*(call_21626431: Call_ListTagsForResource_21626419; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieves the list of key-value tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The resource ARN.
  var path_21626432 = newJObject()
  add(path_21626432, "ResourceArn", newJString(ResourceArn))
  result = call_21626431.call(path_21626432, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626419(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "appconfig.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_21626420, base: "/",
    makeUrl: url_ListTagsForResource_21626421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626449 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626451(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626450(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626452 = path.getOrDefault("ResourceArn")
  valid_21626452 = validateParameter(valid_21626452, JString, required = true,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "ResourceArn", valid_21626452
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626453 = query.getOrDefault("tagKeys")
  valid_21626453 = validateParameter(valid_21626453, JArray, required = true,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "tagKeys", valid_21626453
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
  var valid_21626454 = header.getOrDefault("X-Amz-Date")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Date", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Security-Token", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Algorithm", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Signature")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Signature", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Credential")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Credential", valid_21626460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626461: Call_UntagResource_21626449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a tag key and value from an AppConfig resource.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_UntagResource_21626449; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Deletes a tag key and value from an AppConfig resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to delete.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource for which to remove tags.
  var path_21626463 = newJObject()
  var query_21626464 = newJObject()
  if tagKeys != nil:
    query_21626464.add "tagKeys", tagKeys
  add(path_21626463, "ResourceArn", newJString(ResourceArn))
  result = call_21626462.call(path_21626463, query_21626464, nil, nil, nil)

var untagResource* = Call_UntagResource_21626449(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "appconfig.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_21626450,
    base: "/", makeUrl: url_UntagResource_21626451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidateConfiguration_21626465 = ref object of OpenApiRestCall_21625435
proc url_ValidateConfiguration_21626467(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "ConfigurationProfileId"), (
        kind: ConstantSegment, value: "/validators#configuration_version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ValidateConfiguration_21626466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626468 = path.getOrDefault("ConfigurationProfileId")
  valid_21626468 = validateParameter(valid_21626468, JString, required = true,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "ConfigurationProfileId", valid_21626468
  var valid_21626469 = path.getOrDefault("ApplicationId")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "ApplicationId", valid_21626469
  result.add "path", section
  ## parameters in `query` object:
  ##   configuration_version: JString (required)
  ##                        : The version of the configuration to validate.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `configuration_version` field"
  var valid_21626470 = query.getOrDefault("configuration_version")
  valid_21626470 = validateParameter(valid_21626470, JString, required = true,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "configuration_version", valid_21626470
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
  var valid_21626471 = header.getOrDefault("X-Amz-Date")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Date", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Security-Token", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Algorithm", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Signature")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Signature", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Credential")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Credential", valid_21626477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626478: Call_ValidateConfiguration_21626465;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Uses the validators in a configuration profile to validate a configuration.
  ## 
  let valid = call_21626478.validator(path, query, header, formData, body, _)
  let scheme = call_21626478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626478.makeUrl(scheme.get, call_21626478.host, call_21626478.base,
                               call_21626478.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626478, uri, valid, _)

proc call*(call_21626479: Call_ValidateConfiguration_21626465;
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
  var path_21626480 = newJObject()
  var query_21626481 = newJObject()
  add(path_21626480, "ConfigurationProfileId", newJString(ConfigurationProfileId))
  add(query_21626481, "configuration_version", newJString(configurationVersion))
  add(path_21626480, "ApplicationId", newJString(ApplicationId))
  result = call_21626479.call(path_21626480, query_21626481, nil, nil, nil)

var validateConfiguration* = Call_ValidateConfiguration_21626465(
    name: "validateConfiguration", meth: HttpMethod.HttpPost,
    host: "appconfig.amazonaws.com", route: "/applications/{ApplicationId}/configurationprofiles/{ConfigurationProfileId}/validators#configuration_version",
    validator: validate_ValidateConfiguration_21626466, base: "/",
    makeUrl: url_ValidateConfiguration_21626467,
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
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}