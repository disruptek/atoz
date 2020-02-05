
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Server Migration Service
## version: 2016-10-24
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AAWS Sever Migration Service</fullname> <p>This is the <i>AWS Sever Migration Service API Reference</i>. It provides descriptions, syntax, and usage examples for each of the actions and data types for the AWS Sever Migration Service (AWS SMS). The topic for each action shows the Query API request parameters and the XML response. You can also view the XML request elements in the WSDL.</p> <p>Alternatively, you can use one of the AWS SDKs to access an API that's tailored to the programming language or platform that you're using. For more information, see <a href="http://aws.amazon.com/tools/#SDKs">AWS SDKs</a>.</p> <p>To learn more about the Server Migration Service, see the following resources:</p> <ul> <li> <p> <a href="https://aws.amazon.com/server-migration-service/">AWS Sever Migration Service product page</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/server-migration-service/latest/userguide/server-migration.html">AWS Sever Migration Service User Guide</a> </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sms/
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "sms.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sms.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sms.us-west-2.amazonaws.com",
                           "eu-west-2": "sms.eu-west-2.amazonaws.com", "ap-northeast-3": "sms.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sms.eu-central-1.amazonaws.com",
                           "us-east-2": "sms.us-east-2.amazonaws.com",
                           "us-east-1": "sms.us-east-1.amazonaws.com", "cn-northwest-1": "sms.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sms.ap-south-1.amazonaws.com",
                           "eu-north-1": "sms.eu-north-1.amazonaws.com", "ap-northeast-2": "sms.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sms.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sms.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sms.eu-west-3.amazonaws.com",
                           "cn-north-1": "sms.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sms.sa-east-1.amazonaws.com",
                           "eu-west-1": "sms.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sms.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sms.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sms.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sms.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sms.ap-southeast-1.amazonaws.com",
      "us-west-2": "sms.us-west-2.amazonaws.com",
      "eu-west-2": "sms.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sms.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sms.eu-central-1.amazonaws.com",
      "us-east-2": "sms.us-east-2.amazonaws.com",
      "us-east-1": "sms.us-east-1.amazonaws.com",
      "cn-northwest-1": "sms.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sms.ap-south-1.amazonaws.com",
      "eu-north-1": "sms.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sms.ap-northeast-2.amazonaws.com",
      "us-west-1": "sms.us-west-1.amazonaws.com",
      "us-gov-east-1": "sms.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sms.eu-west-3.amazonaws.com",
      "cn-north-1": "sms.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sms.sa-east-1.amazonaws.com",
      "eu-west-1": "sms.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sms.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sms.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sms.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sms"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_612980 = ref object of OpenApiRestCall_612642
proc url_CreateApp_612982(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_612981(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613107 = header.getOrDefault("X-Amz-Target")
  valid_613107 = validateParameter(valid_613107, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_613107 != nil:
    section.add "X-Amz-Target", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Signature")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Signature", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Content-Sha256", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Date")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Date", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Credential")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Credential", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Security-Token")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Security-Token", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Algorithm")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Algorithm", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-SignedHeaders", valid_613114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613138: Call_CreateApp_612980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  let valid = call_613138.validator(path, query, header, formData, body)
  let scheme = call_613138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613138.url(scheme.get, call_613138.host, call_613138.base,
                         call_613138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613138, url, valid)

proc call*(call_613209: Call_CreateApp_612980; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   body: JObject (required)
  var body_613210 = newJObject()
  if body != nil:
    body_613210 = body
  result = call_613209.call(nil, nil, nil, nil, body_613210)

var createApp* = Call_CreateApp_612980(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
                                    validator: validate_CreateApp_612981,
                                    base: "/", url: url_CreateApp_612982,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_613249 = ref object of OpenApiRestCall_612642
proc url_CreateReplicationJob_613251(protocol: Scheme; host: string; base: string;
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

proc validate_CreateReplicationJob_613250(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613252 = header.getOrDefault("X-Amz-Target")
  valid_613252 = validateParameter(valid_613252, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_613252 != nil:
    section.add "X-Amz-Target", valid_613252
  var valid_613253 = header.getOrDefault("X-Amz-Signature")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-Signature", valid_613253
  var valid_613254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Content-Sha256", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Date")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Date", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Credential")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Credential", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Security-Token")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Security-Token", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Algorithm")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Algorithm", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-SignedHeaders", valid_613259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613261: Call_CreateReplicationJob_613249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  let valid = call_613261.validator(path, query, header, formData, body)
  let scheme = call_613261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613261.url(scheme.get, call_613261.host, call_613261.base,
                         call_613261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613261, url, valid)

proc call*(call_613262: Call_CreateReplicationJob_613249; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   body: JObject (required)
  var body_613263 = newJObject()
  if body != nil:
    body_613263 = body
  result = call_613262.call(nil, nil, nil, nil, body_613263)

var createReplicationJob* = Call_CreateReplicationJob_613249(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_613250, base: "/",
    url: url_CreateReplicationJob_613251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_613264 = ref object of OpenApiRestCall_612642
proc url_DeleteApp_613266(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_613265(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613267 = header.getOrDefault("X-Amz-Target")
  valid_613267 = validateParameter(valid_613267, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_613267 != nil:
    section.add "X-Amz-Target", valid_613267
  var valid_613268 = header.getOrDefault("X-Amz-Signature")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Signature", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Content-Sha256", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Date")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Date", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Credential")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Credential", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Security-Token")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Security-Token", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Algorithm")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Algorithm", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-SignedHeaders", valid_613274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613276: Call_DeleteApp_613264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  let valid = call_613276.validator(path, query, header, formData, body)
  let scheme = call_613276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613276.url(scheme.get, call_613276.host, call_613276.base,
                         call_613276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613276, url, valid)

proc call*(call_613277: Call_DeleteApp_613264; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   body: JObject (required)
  var body_613278 = newJObject()
  if body != nil:
    body_613278 = body
  result = call_613277.call(nil, nil, nil, nil, body_613278)

var deleteApp* = Call_DeleteApp_613264(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
                                    validator: validate_DeleteApp_613265,
                                    base: "/", url: url_DeleteApp_613266,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_613279 = ref object of OpenApiRestCall_612642
proc url_DeleteAppLaunchConfiguration_613281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppLaunchConfiguration_613280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes existing launch configuration for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613282 = header.getOrDefault("X-Amz-Target")
  valid_613282 = validateParameter(valid_613282, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_613282 != nil:
    section.add "X-Amz-Target", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Signature")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Signature", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Content-Sha256", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Date")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Date", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Credential")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Credential", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Security-Token")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Security-Token", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Algorithm")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Algorithm", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-SignedHeaders", valid_613289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613291: Call_DeleteAppLaunchConfiguration_613279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes existing launch configuration for an application.
  ## 
  let valid = call_613291.validator(path, query, header, formData, body)
  let scheme = call_613291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613291.url(scheme.get, call_613291.host, call_613291.base,
                         call_613291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613291, url, valid)

proc call*(call_613292: Call_DeleteAppLaunchConfiguration_613279; body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_613293 = newJObject()
  if body != nil:
    body_613293 = body
  result = call_613292.call(nil, nil, nil, nil, body_613293)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_613279(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_613280, base: "/",
    url: url_DeleteAppLaunchConfiguration_613281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_613294 = ref object of OpenApiRestCall_612642
proc url_DeleteAppReplicationConfiguration_613296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppReplicationConfiguration_613295(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes existing replication configuration for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613297 = header.getOrDefault("X-Amz-Target")
  valid_613297 = validateParameter(valid_613297, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_613297 != nil:
    section.add "X-Amz-Target", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Signature")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Signature", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Content-Sha256", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Date")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Date", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Credential")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Credential", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Security-Token")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Security-Token", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Algorithm")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Algorithm", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-SignedHeaders", valid_613304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613306: Call_DeleteAppReplicationConfiguration_613294;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes existing replication configuration for an application.
  ## 
  let valid = call_613306.validator(path, query, header, formData, body)
  let scheme = call_613306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613306.url(scheme.get, call_613306.host, call_613306.base,
                         call_613306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613306, url, valid)

proc call*(call_613307: Call_DeleteAppReplicationConfiguration_613294;
          body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_613308 = newJObject()
  if body != nil:
    body_613308 = body
  result = call_613307.call(nil, nil, nil, nil, body_613308)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_613294(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_613295, base: "/",
    url: url_DeleteAppReplicationConfiguration_613296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_613309 = ref object of OpenApiRestCall_612642
proc url_DeleteReplicationJob_613311(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReplicationJob_613310(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613312 = header.getOrDefault("X-Amz-Target")
  valid_613312 = validateParameter(valid_613312, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_613312 != nil:
    section.add "X-Amz-Target", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Signature")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Signature", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Content-Sha256", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Date")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Date", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Credential")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Credential", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Security-Token")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Security-Token", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Algorithm")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Algorithm", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-SignedHeaders", valid_613319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613321: Call_DeleteReplicationJob_613309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  let valid = call_613321.validator(path, query, header, formData, body)
  let scheme = call_613321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613321.url(scheme.get, call_613321.host, call_613321.base,
                         call_613321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613321, url, valid)

proc call*(call_613322: Call_DeleteReplicationJob_613309; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   body: JObject (required)
  var body_613323 = newJObject()
  if body != nil:
    body_613323 = body
  result = call_613322.call(nil, nil, nil, nil, body_613323)

var deleteReplicationJob* = Call_DeleteReplicationJob_613309(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_613310, base: "/",
    url: url_DeleteReplicationJob_613311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_613324 = ref object of OpenApiRestCall_612642
proc url_DeleteServerCatalog_613326(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteServerCatalog_613325(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes all servers from your server catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613327 = header.getOrDefault("X-Amz-Target")
  valid_613327 = validateParameter(valid_613327, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_613327 != nil:
    section.add "X-Amz-Target", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Signature")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Signature", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Content-Sha256", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Date")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Date", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Credential")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Credential", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Security-Token")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Security-Token", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Algorithm")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Algorithm", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-SignedHeaders", valid_613334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613336: Call_DeleteServerCatalog_613324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all servers from your server catalog.
  ## 
  let valid = call_613336.validator(path, query, header, formData, body)
  let scheme = call_613336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613336.url(scheme.get, call_613336.host, call_613336.base,
                         call_613336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613336, url, valid)

proc call*(call_613337: Call_DeleteServerCatalog_613324; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_613338 = newJObject()
  if body != nil:
    body_613338 = body
  result = call_613337.call(nil, nil, nil, nil, body_613338)

var deleteServerCatalog* = Call_DeleteServerCatalog_613324(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_613325, base: "/",
    url: url_DeleteServerCatalog_613326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_613339 = ref object of OpenApiRestCall_612642
proc url_DisassociateConnector_613341(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateConnector_613340(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613342 = header.getOrDefault("X-Amz-Target")
  valid_613342 = validateParameter(valid_613342, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_613342 != nil:
    section.add "X-Amz-Target", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Signature")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Signature", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Content-Sha256", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Date")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Date", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Credential")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Credential", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Security-Token")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Security-Token", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Algorithm")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Algorithm", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-SignedHeaders", valid_613349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613351: Call_DisassociateConnector_613339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  let valid = call_613351.validator(path, query, header, formData, body)
  let scheme = call_613351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613351.url(scheme.get, call_613351.host, call_613351.base,
                         call_613351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613351, url, valid)

proc call*(call_613352: Call_DisassociateConnector_613339; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   body: JObject (required)
  var body_613353 = newJObject()
  if body != nil:
    body_613353 = body
  result = call_613352.call(nil, nil, nil, nil, body_613353)

var disassociateConnector* = Call_DisassociateConnector_613339(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_613340, base: "/",
    url: url_DisassociateConnector_613341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_613354 = ref object of OpenApiRestCall_612642
proc url_GenerateChangeSet_613356(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateChangeSet_613355(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613357 = header.getOrDefault("X-Amz-Target")
  valid_613357 = validateParameter(valid_613357, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_613357 != nil:
    section.add "X-Amz-Target", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Signature")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Signature", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Content-Sha256", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Date")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Date", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Credential")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Credential", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Security-Token")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Security-Token", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Algorithm")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Algorithm", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-SignedHeaders", valid_613364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613366: Call_GenerateChangeSet_613354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_613366.validator(path, query, header, formData, body)
  let scheme = call_613366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613366.url(scheme.get, call_613366.host, call_613366.base,
                         call_613366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613366, url, valid)

proc call*(call_613367: Call_GenerateChangeSet_613354; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_613368 = newJObject()
  if body != nil:
    body_613368 = body
  result = call_613367.call(nil, nil, nil, nil, body_613368)

var generateChangeSet* = Call_GenerateChangeSet_613354(name: "generateChangeSet",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_613355, base: "/",
    url: url_GenerateChangeSet_613356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_613369 = ref object of OpenApiRestCall_612642
proc url_GenerateTemplate_613371(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateTemplate_613370(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613372 = header.getOrDefault("X-Amz-Target")
  valid_613372 = validateParameter(valid_613372, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_613372 != nil:
    section.add "X-Amz-Target", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Signature")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Signature", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Content-Sha256", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Date")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Date", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Credential")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Credential", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Security-Token")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Security-Token", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Algorithm")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Algorithm", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-SignedHeaders", valid_613379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613381: Call_GenerateTemplate_613369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_613381.validator(path, query, header, formData, body)
  let scheme = call_613381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613381.url(scheme.get, call_613381.host, call_613381.base,
                         call_613381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613381, url, valid)

proc call*(call_613382: Call_GenerateTemplate_613369; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_613383 = newJObject()
  if body != nil:
    body_613383 = body
  result = call_613382.call(nil, nil, nil, nil, body_613383)

var generateTemplate* = Call_GenerateTemplate_613369(name: "generateTemplate",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_613370, base: "/",
    url: url_GenerateTemplate_613371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_613384 = ref object of OpenApiRestCall_612642
proc url_GetApp_613386(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApp_613385(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve information about an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613387 = header.getOrDefault("X-Amz-Target")
  valid_613387 = validateParameter(valid_613387, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_613387 != nil:
    section.add "X-Amz-Target", valid_613387
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613396: Call_GetApp_613384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_613396.validator(path, query, header, formData, body)
  let scheme = call_613396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613396.url(scheme.get, call_613396.host, call_613396.base,
                         call_613396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613396, url, valid)

proc call*(call_613397: Call_GetApp_613384; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_613398 = newJObject()
  if body != nil:
    body_613398 = body
  result = call_613397.call(nil, nil, nil, nil, body_613398)

var getApp* = Call_GetApp_613384(name: "getApp", meth: HttpMethod.HttpPost,
                              host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                              validator: validate_GetApp_613385, base: "/",
                              url: url_GetApp_613386,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_613399 = ref object of OpenApiRestCall_612642
proc url_GetAppLaunchConfiguration_613401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppLaunchConfiguration_613400(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613402 = header.getOrDefault("X-Amz-Target")
  valid_613402 = validateParameter(valid_613402, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_613402 != nil:
    section.add "X-Amz-Target", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Signature")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Signature", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Content-Sha256", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Date")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Date", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Credential")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Credential", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Security-Token")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Security-Token", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Algorithm")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Algorithm", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-SignedHeaders", valid_613409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613411: Call_GetAppLaunchConfiguration_613399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  let valid = call_613411.validator(path, query, header, formData, body)
  let scheme = call_613411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613411.url(scheme.get, call_613411.host, call_613411.base,
                         call_613411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613411, url, valid)

proc call*(call_613412: Call_GetAppLaunchConfiguration_613399; body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   body: JObject (required)
  var body_613413 = newJObject()
  if body != nil:
    body_613413 = body
  result = call_613412.call(nil, nil, nil, nil, body_613413)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_613399(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_613400, base: "/",
    url: url_GetAppLaunchConfiguration_613401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_613414 = ref object of OpenApiRestCall_612642
proc url_GetAppReplicationConfiguration_613416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppReplicationConfiguration_613415(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613417 = header.getOrDefault("X-Amz-Target")
  valid_613417 = validateParameter(valid_613417, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_613417 != nil:
    section.add "X-Amz-Target", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Signature")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Signature", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Content-Sha256", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Date")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Date", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Credential")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Credential", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Security-Token")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Security-Token", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Algorithm")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Algorithm", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-SignedHeaders", valid_613424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613426: Call_GetAppReplicationConfiguration_613414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  let valid = call_613426.validator(path, query, header, formData, body)
  let scheme = call_613426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613426.url(scheme.get, call_613426.host, call_613426.base,
                         call_613426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613426, url, valid)

proc call*(call_613427: Call_GetAppReplicationConfiguration_613414; body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   body: JObject (required)
  var body_613428 = newJObject()
  if body != nil:
    body_613428 = body
  result = call_613427.call(nil, nil, nil, nil, body_613428)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_613414(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_613415, base: "/",
    url: url_GetAppReplicationConfiguration_613416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_613429 = ref object of OpenApiRestCall_612642
proc url_GetConnectors_613431(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectors_613430(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613432 = query.getOrDefault("nextToken")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "nextToken", valid_613432
  var valid_613433 = query.getOrDefault("maxResults")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "maxResults", valid_613433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613434 = header.getOrDefault("X-Amz-Target")
  valid_613434 = validateParameter(valid_613434, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_613434 != nil:
    section.add "X-Amz-Target", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Signature")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Signature", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Content-Sha256", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Date")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Date", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Credential")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Credential", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Security-Token")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Security-Token", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Algorithm")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Algorithm", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-SignedHeaders", valid_613441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613443: Call_GetConnectors_613429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  let valid = call_613443.validator(path, query, header, formData, body)
  let scheme = call_613443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613443.url(scheme.get, call_613443.host, call_613443.base,
                         call_613443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613443, url, valid)

proc call*(call_613444: Call_GetConnectors_613429; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613445 = newJObject()
  var body_613446 = newJObject()
  add(query_613445, "nextToken", newJString(nextToken))
  if body != nil:
    body_613446 = body
  add(query_613445, "maxResults", newJString(maxResults))
  result = call_613444.call(nil, query_613445, nil, nil, body_613446)

var getConnectors* = Call_GetConnectors_613429(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_613430, base: "/", url: url_GetConnectors_613431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_613448 = ref object of OpenApiRestCall_612642
proc url_GetReplicationJobs_613450(protocol: Scheme; host: string; base: string;
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

proc validate_GetReplicationJobs_613449(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613451 = query.getOrDefault("nextToken")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "nextToken", valid_613451
  var valid_613452 = query.getOrDefault("maxResults")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "maxResults", valid_613452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613453 = header.getOrDefault("X-Amz-Target")
  valid_613453 = validateParameter(valid_613453, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_613453 != nil:
    section.add "X-Amz-Target", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Signature")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Signature", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Content-Sha256", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Date")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Date", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Credential")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Credential", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Security-Token")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Security-Token", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Algorithm")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Algorithm", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-SignedHeaders", valid_613460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613462: Call_GetReplicationJobs_613448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  let valid = call_613462.validator(path, query, header, formData, body)
  let scheme = call_613462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613462.url(scheme.get, call_613462.host, call_613462.base,
                         call_613462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613462, url, valid)

proc call*(call_613463: Call_GetReplicationJobs_613448; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613464 = newJObject()
  var body_613465 = newJObject()
  add(query_613464, "nextToken", newJString(nextToken))
  if body != nil:
    body_613465 = body
  add(query_613464, "maxResults", newJString(maxResults))
  result = call_613463.call(nil, query_613464, nil, nil, body_613465)

var getReplicationJobs* = Call_GetReplicationJobs_613448(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_613449, base: "/",
    url: url_GetReplicationJobs_613450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_613466 = ref object of OpenApiRestCall_612642
proc url_GetReplicationRuns_613468(protocol: Scheme; host: string; base: string;
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

proc validate_GetReplicationRuns_613467(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes the replication runs for the specified replication job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613469 = query.getOrDefault("nextToken")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "nextToken", valid_613469
  var valid_613470 = query.getOrDefault("maxResults")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "maxResults", valid_613470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613471 = header.getOrDefault("X-Amz-Target")
  valid_613471 = validateParameter(valid_613471, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_613471 != nil:
    section.add "X-Amz-Target", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Signature")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Signature", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Content-Sha256", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Date")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Date", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Credential")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Credential", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Security-Token")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Security-Token", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Algorithm")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Algorithm", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-SignedHeaders", valid_613478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613480: Call_GetReplicationRuns_613466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the replication runs for the specified replication job.
  ## 
  let valid = call_613480.validator(path, query, header, formData, body)
  let scheme = call_613480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613480.url(scheme.get, call_613480.host, call_613480.base,
                         call_613480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613480, url, valid)

proc call*(call_613481: Call_GetReplicationRuns_613466; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613482 = newJObject()
  var body_613483 = newJObject()
  add(query_613482, "nextToken", newJString(nextToken))
  if body != nil:
    body_613483 = body
  add(query_613482, "maxResults", newJString(maxResults))
  result = call_613481.call(nil, query_613482, nil, nil, body_613483)

var getReplicationRuns* = Call_GetReplicationRuns_613466(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_613467, base: "/",
    url: url_GetReplicationRuns_613468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_613484 = ref object of OpenApiRestCall_612642
proc url_GetServers_613486(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServers_613485(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613487 = query.getOrDefault("nextToken")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "nextToken", valid_613487
  var valid_613488 = query.getOrDefault("maxResults")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "maxResults", valid_613488
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613489 = header.getOrDefault("X-Amz-Target")
  valid_613489 = validateParameter(valid_613489, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_613489 != nil:
    section.add "X-Amz-Target", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Signature")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Signature", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Content-Sha256", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Date")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Date", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Credential")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Credential", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Security-Token")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Security-Token", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Algorithm")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Algorithm", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-SignedHeaders", valid_613496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613498: Call_GetServers_613484; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  let valid = call_613498.validator(path, query, header, formData, body)
  let scheme = call_613498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613498.url(scheme.get, call_613498.host, call_613498.base,
                         call_613498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613498, url, valid)

proc call*(call_613499: Call_GetServers_613484; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613500 = newJObject()
  var body_613501 = newJObject()
  add(query_613500, "nextToken", newJString(nextToken))
  if body != nil:
    body_613501 = body
  add(query_613500, "maxResults", newJString(maxResults))
  result = call_613499.call(nil, query_613500, nil, nil, body_613501)

var getServers* = Call_GetServers_613484(name: "getServers",
                                      meth: HttpMethod.HttpPost,
                                      host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
                                      validator: validate_GetServers_613485,
                                      base: "/", url: url_GetServers_613486,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_613502 = ref object of OpenApiRestCall_612642
proc url_ImportServerCatalog_613504(protocol: Scheme; host: string; base: string;
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

proc validate_ImportServerCatalog_613503(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613505 = header.getOrDefault("X-Amz-Target")
  valid_613505 = validateParameter(valid_613505, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_613505 != nil:
    section.add "X-Amz-Target", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Signature")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Signature", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Content-Sha256", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Date")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Date", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Credential")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Credential", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Security-Token")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Security-Token", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Algorithm")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Algorithm", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-SignedHeaders", valid_613512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613514: Call_ImportServerCatalog_613502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  let valid = call_613514.validator(path, query, header, formData, body)
  let scheme = call_613514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613514.url(scheme.get, call_613514.host, call_613514.base,
                         call_613514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613514, url, valid)

proc call*(call_613515: Call_ImportServerCatalog_613502; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   body: JObject (required)
  var body_613516 = newJObject()
  if body != nil:
    body_613516 = body
  result = call_613515.call(nil, nil, nil, nil, body_613516)

var importServerCatalog* = Call_ImportServerCatalog_613502(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_613503, base: "/",
    url: url_ImportServerCatalog_613504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_613517 = ref object of OpenApiRestCall_612642
proc url_LaunchApp_613519(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LaunchApp_613518(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Launches an application stack.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613520 = header.getOrDefault("X-Amz-Target")
  valid_613520 = validateParameter(valid_613520, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_613520 != nil:
    section.add "X-Amz-Target", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Signature")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Signature", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Content-Sha256", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Date")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Date", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Credential")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Credential", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Security-Token")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Security-Token", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Algorithm")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Algorithm", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-SignedHeaders", valid_613527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613529: Call_LaunchApp_613517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an application stack.
  ## 
  let valid = call_613529.validator(path, query, header, formData, body)
  let scheme = call_613529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613529.url(scheme.get, call_613529.host, call_613529.base,
                         call_613529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613529, url, valid)

proc call*(call_613530: Call_LaunchApp_613517; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_613531 = newJObject()
  if body != nil:
    body_613531 = body
  result = call_613530.call(nil, nil, nil, nil, body_613531)

var launchApp* = Call_LaunchApp_613517(name: "launchApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
                                    validator: validate_LaunchApp_613518,
                                    base: "/", url: url_LaunchApp_613519,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_613532 = ref object of OpenApiRestCall_612642
proc url_ListApps_613534(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_613533(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of summaries for all applications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613535 = header.getOrDefault("X-Amz-Target")
  valid_613535 = validateParameter(valid_613535, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_613535 != nil:
    section.add "X-Amz-Target", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Signature")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Signature", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Content-Sha256", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Date")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Date", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Credential")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Credential", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Security-Token")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Security-Token", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Algorithm")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Algorithm", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-SignedHeaders", valid_613542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613544: Call_ListApps_613532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of summaries for all applications.
  ## 
  let valid = call_613544.validator(path, query, header, formData, body)
  let scheme = call_613544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613544.url(scheme.get, call_613544.host, call_613544.base,
                         call_613544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613544, url, valid)

proc call*(call_613545: Call_ListApps_613532; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_613546 = newJObject()
  if body != nil:
    body_613546 = body
  result = call_613545.call(nil, nil, nil, nil, body_613546)

var listApps* = Call_ListApps_613532(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                  validator: validate_ListApps_613533, base: "/",
                                  url: url_ListApps_613534,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_613547 = ref object of OpenApiRestCall_612642
proc url_PutAppLaunchConfiguration_613549(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppLaunchConfiguration_613548(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a launch configuration for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613550 = header.getOrDefault("X-Amz-Target")
  valid_613550 = validateParameter(valid_613550, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_613550 != nil:
    section.add "X-Amz-Target", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Signature")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Signature", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Content-Sha256", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Date")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Date", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Credential")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Credential", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Security-Token")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Security-Token", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Algorithm")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Algorithm", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-SignedHeaders", valid_613557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613559: Call_PutAppLaunchConfiguration_613547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a launch configuration for an application.
  ## 
  let valid = call_613559.validator(path, query, header, formData, body)
  let scheme = call_613559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613559.url(scheme.get, call_613559.host, call_613559.base,
                         call_613559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613559, url, valid)

proc call*(call_613560: Call_PutAppLaunchConfiguration_613547; body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_613561 = newJObject()
  if body != nil:
    body_613561 = body
  result = call_613560.call(nil, nil, nil, nil, body_613561)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_613547(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_613548, base: "/",
    url: url_PutAppLaunchConfiguration_613549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_613562 = ref object of OpenApiRestCall_612642
proc url_PutAppReplicationConfiguration_613564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppReplicationConfiguration_613563(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or updates a replication configuration for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613565 = header.getOrDefault("X-Amz-Target")
  valid_613565 = validateParameter(valid_613565, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_613565 != nil:
    section.add "X-Amz-Target", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Signature")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Signature", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Content-Sha256", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Date")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Date", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Credential")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Credential", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Security-Token")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Security-Token", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Algorithm")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Algorithm", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-SignedHeaders", valid_613572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613574: Call_PutAppReplicationConfiguration_613562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a replication configuration for an application.
  ## 
  let valid = call_613574.validator(path, query, header, formData, body)
  let scheme = call_613574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613574.url(scheme.get, call_613574.host, call_613574.base,
                         call_613574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613574, url, valid)

proc call*(call_613575: Call_PutAppReplicationConfiguration_613562; body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject (required)
  var body_613576 = newJObject()
  if body != nil:
    body_613576 = body
  result = call_613575.call(nil, nil, nil, nil, body_613576)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_613562(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_613563, base: "/",
    url: url_PutAppReplicationConfiguration_613564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_613577 = ref object of OpenApiRestCall_612642
proc url_StartAppReplication_613579(protocol: Scheme; host: string; base: string;
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

proc validate_StartAppReplication_613578(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Starts replicating an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613580 = header.getOrDefault("X-Amz-Target")
  valid_613580 = validateParameter(valid_613580, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_613580 != nil:
    section.add "X-Amz-Target", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Signature")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Signature", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Content-Sha256", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Date")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Date", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Credential")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Credential", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Security-Token")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Security-Token", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Algorithm")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Algorithm", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-SignedHeaders", valid_613587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613589: Call_StartAppReplication_613577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts replicating an application.
  ## 
  let valid = call_613589.validator(path, query, header, formData, body)
  let scheme = call_613589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613589.url(scheme.get, call_613589.host, call_613589.base,
                         call_613589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613589, url, valid)

proc call*(call_613590: Call_StartAppReplication_613577; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_613591 = newJObject()
  if body != nil:
    body_613591 = body
  result = call_613590.call(nil, nil, nil, nil, body_613591)

var startAppReplication* = Call_StartAppReplication_613577(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_613578, base: "/",
    url: url_StartAppReplication_613579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_613592 = ref object of OpenApiRestCall_612642
proc url_StartOnDemandReplicationRun_613594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartOnDemandReplicationRun_613593(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613595 = header.getOrDefault("X-Amz-Target")
  valid_613595 = validateParameter(valid_613595, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_613595 != nil:
    section.add "X-Amz-Target", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-Signature")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Signature", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Content-Sha256", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Date")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Date", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Credential")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Credential", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Security-Token")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Security-Token", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Algorithm")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Algorithm", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-SignedHeaders", valid_613602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613604: Call_StartOnDemandReplicationRun_613592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  let valid = call_613604.validator(path, query, header, formData, body)
  let scheme = call_613604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613604.url(scheme.get, call_613604.host, call_613604.base,
                         call_613604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613604, url, valid)

proc call*(call_613605: Call_StartOnDemandReplicationRun_613592; body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_613606 = newJObject()
  if body != nil:
    body_613606 = body
  result = call_613605.call(nil, nil, nil, nil, body_613606)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_613592(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_613593, base: "/",
    url: url_StartOnDemandReplicationRun_613594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_613607 = ref object of OpenApiRestCall_612642
proc url_StopAppReplication_613609(protocol: Scheme; host: string; base: string;
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

proc validate_StopAppReplication_613608(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Stops replicating an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613610 = header.getOrDefault("X-Amz-Target")
  valid_613610 = validateParameter(valid_613610, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_613610 != nil:
    section.add "X-Amz-Target", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Signature")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Signature", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Content-Sha256", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Date")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Date", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Credential")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Credential", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Security-Token")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Security-Token", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Algorithm")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Algorithm", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-SignedHeaders", valid_613617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613619: Call_StopAppReplication_613607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops replicating an application.
  ## 
  let valid = call_613619.validator(path, query, header, formData, body)
  let scheme = call_613619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613619.url(scheme.get, call_613619.host, call_613619.base,
                         call_613619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613619, url, valid)

proc call*(call_613620: Call_StopAppReplication_613607; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_613621 = newJObject()
  if body != nil:
    body_613621 = body
  result = call_613620.call(nil, nil, nil, nil, body_613621)

var stopAppReplication* = Call_StopAppReplication_613607(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_613608, base: "/",
    url: url_StopAppReplication_613609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_613622 = ref object of OpenApiRestCall_612642
proc url_TerminateApp_613624(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateApp_613623(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Terminates the stack for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613625 = header.getOrDefault("X-Amz-Target")
  valid_613625 = validateParameter(valid_613625, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_613625 != nil:
    section.add "X-Amz-Target", valid_613625
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613634: Call_TerminateApp_613622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the stack for an application.
  ## 
  let valid = call_613634.validator(path, query, header, formData, body)
  let scheme = call_613634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613634.url(scheme.get, call_613634.host, call_613634.base,
                         call_613634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613634, url, valid)

proc call*(call_613635: Call_TerminateApp_613622; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_613636 = newJObject()
  if body != nil:
    body_613636 = body
  result = call_613635.call(nil, nil, nil, nil, body_613636)

var terminateApp* = Call_TerminateApp_613622(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_613623, base: "/", url: url_TerminateApp_613624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_613637 = ref object of OpenApiRestCall_612642
proc url_UpdateApp_613639(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApp_613638(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613640 = header.getOrDefault("X-Amz-Target")
  valid_613640 = validateParameter(valid_613640, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_613640 != nil:
    section.add "X-Amz-Target", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Signature")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Signature", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Content-Sha256", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Date")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Date", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Credential")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Credential", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Security-Token")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Security-Token", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Algorithm")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Algorithm", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-SignedHeaders", valid_613647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613649: Call_UpdateApp_613637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_613649.validator(path, query, header, formData, body)
  let scheme = call_613649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613649.url(scheme.get, call_613649.host, call_613649.base,
                         call_613649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613649, url, valid)

proc call*(call_613650: Call_UpdateApp_613637; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_613651 = newJObject()
  if body != nil:
    body_613651 = body
  result = call_613650.call(nil, nil, nil, nil, body_613651)

var updateApp* = Call_UpdateApp_613637(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
                                    validator: validate_UpdateApp_613638,
                                    base: "/", url: url_UpdateApp_613639,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_613652 = ref object of OpenApiRestCall_612642
proc url_UpdateReplicationJob_613654(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateReplicationJob_613653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified settings for the specified replication job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613655 = header.getOrDefault("X-Amz-Target")
  valid_613655 = validateParameter(valid_613655, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_613655 != nil:
    section.add "X-Amz-Target", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Signature")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Signature", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Content-Sha256", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Date")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Date", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Credential")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Credential", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Security-Token")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Security-Token", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Algorithm")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Algorithm", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-SignedHeaders", valid_613662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613664: Call_UpdateReplicationJob_613652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified settings for the specified replication job.
  ## 
  let valid = call_613664.validator(path, query, header, formData, body)
  let scheme = call_613664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613664.url(scheme.get, call_613664.host, call_613664.base,
                         call_613664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613664, url, valid)

proc call*(call_613665: Call_UpdateReplicationJob_613652; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_613666 = newJObject()
  if body != nil:
    body_613666 = body
  result = call_613665.call(nil, nil, nil, nil, body_613666)

var updateReplicationJob* = Call_UpdateReplicationJob_613652(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_613653, base: "/",
    url: url_UpdateReplicationJob_613654, schemes: {Scheme.Https, Scheme.Http})
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
