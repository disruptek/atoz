
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
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
  Call_CreateApp_610980 = ref object of OpenApiRestCall_610642
proc url_CreateApp_610982(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_610981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611107 = header.getOrDefault("X-Amz-Target")
  valid_611107 = validateParameter(valid_611107, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_611107 != nil:
    section.add "X-Amz-Target", valid_611107
  var valid_611108 = header.getOrDefault("X-Amz-Signature")
  valid_611108 = validateParameter(valid_611108, JString, required = false,
                                 default = nil)
  if valid_611108 != nil:
    section.add "X-Amz-Signature", valid_611108
  var valid_611109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611109 = validateParameter(valid_611109, JString, required = false,
                                 default = nil)
  if valid_611109 != nil:
    section.add "X-Amz-Content-Sha256", valid_611109
  var valid_611110 = header.getOrDefault("X-Amz-Date")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Date", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Credential")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Credential", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Security-Token")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Security-Token", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Algorithm")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Algorithm", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-SignedHeaders", valid_611114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611138: Call_CreateApp_610980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  let valid = call_611138.validator(path, query, header, formData, body)
  let scheme = call_611138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611138.url(scheme.get, call_611138.host, call_611138.base,
                         call_611138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611138, url, valid)

proc call*(call_611209: Call_CreateApp_610980; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   body: JObject (required)
  var body_611210 = newJObject()
  if body != nil:
    body_611210 = body
  result = call_611209.call(nil, nil, nil, nil, body_611210)

var createApp* = Call_CreateApp_610980(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
                                    validator: validate_CreateApp_610981,
                                    base: "/", url: url_CreateApp_610982,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_611249 = ref object of OpenApiRestCall_610642
proc url_CreateReplicationJob_611251(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReplicationJob_611250(path: JsonNode; query: JsonNode;
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
  var valid_611252 = header.getOrDefault("X-Amz-Target")
  valid_611252 = validateParameter(valid_611252, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_611252 != nil:
    section.add "X-Amz-Target", valid_611252
  var valid_611253 = header.getOrDefault("X-Amz-Signature")
  valid_611253 = validateParameter(valid_611253, JString, required = false,
                                 default = nil)
  if valid_611253 != nil:
    section.add "X-Amz-Signature", valid_611253
  var valid_611254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611254 = validateParameter(valid_611254, JString, required = false,
                                 default = nil)
  if valid_611254 != nil:
    section.add "X-Amz-Content-Sha256", valid_611254
  var valid_611255 = header.getOrDefault("X-Amz-Date")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Date", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Credential")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Credential", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Security-Token")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Security-Token", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Algorithm")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Algorithm", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-SignedHeaders", valid_611259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611261: Call_CreateReplicationJob_611249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  let valid = call_611261.validator(path, query, header, formData, body)
  let scheme = call_611261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611261.url(scheme.get, call_611261.host, call_611261.base,
                         call_611261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611261, url, valid)

proc call*(call_611262: Call_CreateReplicationJob_611249; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   body: JObject (required)
  var body_611263 = newJObject()
  if body != nil:
    body_611263 = body
  result = call_611262.call(nil, nil, nil, nil, body_611263)

var createReplicationJob* = Call_CreateReplicationJob_611249(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_611250, base: "/",
    url: url_CreateReplicationJob_611251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_611264 = ref object of OpenApiRestCall_610642
proc url_DeleteApp_611266(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_611265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611267 = header.getOrDefault("X-Amz-Target")
  valid_611267 = validateParameter(valid_611267, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_611267 != nil:
    section.add "X-Amz-Target", valid_611267
  var valid_611268 = header.getOrDefault("X-Amz-Signature")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Signature", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Content-Sha256", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Date")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Date", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Credential")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Credential", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Security-Token")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Security-Token", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Algorithm")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Algorithm", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-SignedHeaders", valid_611274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611276: Call_DeleteApp_611264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  let valid = call_611276.validator(path, query, header, formData, body)
  let scheme = call_611276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611276.url(scheme.get, call_611276.host, call_611276.base,
                         call_611276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611276, url, valid)

proc call*(call_611277: Call_DeleteApp_611264; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   body: JObject (required)
  var body_611278 = newJObject()
  if body != nil:
    body_611278 = body
  result = call_611277.call(nil, nil, nil, nil, body_611278)

var deleteApp* = Call_DeleteApp_611264(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
                                    validator: validate_DeleteApp_611265,
                                    base: "/", url: url_DeleteApp_611266,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_611279 = ref object of OpenApiRestCall_610642
proc url_DeleteAppLaunchConfiguration_611281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppLaunchConfiguration_611280(path: JsonNode; query: JsonNode;
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
  var valid_611282 = header.getOrDefault("X-Amz-Target")
  valid_611282 = validateParameter(valid_611282, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_611282 != nil:
    section.add "X-Amz-Target", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Signature")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Signature", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Content-Sha256", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Date")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Date", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Credential")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Credential", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Security-Token")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Security-Token", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Algorithm")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Algorithm", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-SignedHeaders", valid_611289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611291: Call_DeleteAppLaunchConfiguration_611279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes existing launch configuration for an application.
  ## 
  let valid = call_611291.validator(path, query, header, formData, body)
  let scheme = call_611291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611291.url(scheme.get, call_611291.host, call_611291.base,
                         call_611291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611291, url, valid)

proc call*(call_611292: Call_DeleteAppLaunchConfiguration_611279; body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_611293 = newJObject()
  if body != nil:
    body_611293 = body
  result = call_611292.call(nil, nil, nil, nil, body_611293)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_611279(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_611280, base: "/",
    url: url_DeleteAppLaunchConfiguration_611281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_611294 = ref object of OpenApiRestCall_610642
proc url_DeleteAppReplicationConfiguration_611296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppReplicationConfiguration_611295(path: JsonNode;
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
  var valid_611297 = header.getOrDefault("X-Amz-Target")
  valid_611297 = validateParameter(valid_611297, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_611297 != nil:
    section.add "X-Amz-Target", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Signature")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Signature", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Content-Sha256", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Date")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Date", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Credential")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Credential", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Security-Token")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Security-Token", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Algorithm")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Algorithm", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-SignedHeaders", valid_611304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611306: Call_DeleteAppReplicationConfiguration_611294;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes existing replication configuration for an application.
  ## 
  let valid = call_611306.validator(path, query, header, formData, body)
  let scheme = call_611306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611306.url(scheme.get, call_611306.host, call_611306.base,
                         call_611306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611306, url, valid)

proc call*(call_611307: Call_DeleteAppReplicationConfiguration_611294;
          body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_611308 = newJObject()
  if body != nil:
    body_611308 = body
  result = call_611307.call(nil, nil, nil, nil, body_611308)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_611294(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_611295, base: "/",
    url: url_DeleteAppReplicationConfiguration_611296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_611309 = ref object of OpenApiRestCall_610642
proc url_DeleteReplicationJob_611311(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReplicationJob_611310(path: JsonNode; query: JsonNode;
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
  var valid_611312 = header.getOrDefault("X-Amz-Target")
  valid_611312 = validateParameter(valid_611312, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_611312 != nil:
    section.add "X-Amz-Target", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Signature")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Signature", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Content-Sha256", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Date")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Date", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Credential")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Credential", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Security-Token")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Security-Token", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Algorithm")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Algorithm", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-SignedHeaders", valid_611319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611321: Call_DeleteReplicationJob_611309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  let valid = call_611321.validator(path, query, header, formData, body)
  let scheme = call_611321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611321.url(scheme.get, call_611321.host, call_611321.base,
                         call_611321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611321, url, valid)

proc call*(call_611322: Call_DeleteReplicationJob_611309; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   body: JObject (required)
  var body_611323 = newJObject()
  if body != nil:
    body_611323 = body
  result = call_611322.call(nil, nil, nil, nil, body_611323)

var deleteReplicationJob* = Call_DeleteReplicationJob_611309(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_611310, base: "/",
    url: url_DeleteReplicationJob_611311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_611324 = ref object of OpenApiRestCall_610642
proc url_DeleteServerCatalog_611326(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServerCatalog_611325(path: JsonNode; query: JsonNode;
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
  var valid_611327 = header.getOrDefault("X-Amz-Target")
  valid_611327 = validateParameter(valid_611327, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_611327 != nil:
    section.add "X-Amz-Target", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Signature")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Signature", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Content-Sha256", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Date")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Date", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Credential")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Credential", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Security-Token")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Security-Token", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Algorithm")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Algorithm", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-SignedHeaders", valid_611334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611336: Call_DeleteServerCatalog_611324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all servers from your server catalog.
  ## 
  let valid = call_611336.validator(path, query, header, formData, body)
  let scheme = call_611336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611336.url(scheme.get, call_611336.host, call_611336.base,
                         call_611336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611336, url, valid)

proc call*(call_611337: Call_DeleteServerCatalog_611324; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_611338 = newJObject()
  if body != nil:
    body_611338 = body
  result = call_611337.call(nil, nil, nil, nil, body_611338)

var deleteServerCatalog* = Call_DeleteServerCatalog_611324(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_611325, base: "/",
    url: url_DeleteServerCatalog_611326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_611339 = ref object of OpenApiRestCall_610642
proc url_DisassociateConnector_611341(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConnector_611340(path: JsonNode; query: JsonNode;
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
  var valid_611342 = header.getOrDefault("X-Amz-Target")
  valid_611342 = validateParameter(valid_611342, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_611342 != nil:
    section.add "X-Amz-Target", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Signature")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Signature", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Content-Sha256", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Date")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Date", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Credential")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Credential", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Security-Token")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Security-Token", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Algorithm")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Algorithm", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-SignedHeaders", valid_611349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611351: Call_DisassociateConnector_611339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  let valid = call_611351.validator(path, query, header, formData, body)
  let scheme = call_611351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611351.url(scheme.get, call_611351.host, call_611351.base,
                         call_611351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611351, url, valid)

proc call*(call_611352: Call_DisassociateConnector_611339; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   body: JObject (required)
  var body_611353 = newJObject()
  if body != nil:
    body_611353 = body
  result = call_611352.call(nil, nil, nil, nil, body_611353)

var disassociateConnector* = Call_DisassociateConnector_611339(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_611340, base: "/",
    url: url_DisassociateConnector_611341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_611354 = ref object of OpenApiRestCall_610642
proc url_GenerateChangeSet_611356(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateChangeSet_611355(path: JsonNode; query: JsonNode;
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
  var valid_611357 = header.getOrDefault("X-Amz-Target")
  valid_611357 = validateParameter(valid_611357, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_611357 != nil:
    section.add "X-Amz-Target", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Signature")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Signature", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Content-Sha256", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Date")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Date", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Credential")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Credential", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Security-Token")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Security-Token", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Algorithm")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Algorithm", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-SignedHeaders", valid_611364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611366: Call_GenerateChangeSet_611354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_611366.validator(path, query, header, formData, body)
  let scheme = call_611366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611366.url(scheme.get, call_611366.host, call_611366.base,
                         call_611366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611366, url, valid)

proc call*(call_611367: Call_GenerateChangeSet_611354; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_611368 = newJObject()
  if body != nil:
    body_611368 = body
  result = call_611367.call(nil, nil, nil, nil, body_611368)

var generateChangeSet* = Call_GenerateChangeSet_611354(name: "generateChangeSet",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_611355, base: "/",
    url: url_GenerateChangeSet_611356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_611369 = ref object of OpenApiRestCall_610642
proc url_GenerateTemplate_611371(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateTemplate_611370(path: JsonNode; query: JsonNode;
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
  var valid_611372 = header.getOrDefault("X-Amz-Target")
  valid_611372 = validateParameter(valid_611372, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_611372 != nil:
    section.add "X-Amz-Target", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Signature")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Signature", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Content-Sha256", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Date")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Date", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Credential")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Credential", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Security-Token")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Security-Token", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Algorithm")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Algorithm", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-SignedHeaders", valid_611379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611381: Call_GenerateTemplate_611369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_611381.validator(path, query, header, formData, body)
  let scheme = call_611381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611381.url(scheme.get, call_611381.host, call_611381.base,
                         call_611381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611381, url, valid)

proc call*(call_611382: Call_GenerateTemplate_611369; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_611383 = newJObject()
  if body != nil:
    body_611383 = body
  result = call_611382.call(nil, nil, nil, nil, body_611383)

var generateTemplate* = Call_GenerateTemplate_611369(name: "generateTemplate",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_611370, base: "/",
    url: url_GenerateTemplate_611371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_611384 = ref object of OpenApiRestCall_610642
proc url_GetApp_611386(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApp_611385(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611387 = header.getOrDefault("X-Amz-Target")
  valid_611387 = validateParameter(valid_611387, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_611387 != nil:
    section.add "X-Amz-Target", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Signature")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Signature", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Content-Sha256", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Date")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Date", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Credential")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Credential", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Security-Token")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Security-Token", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Algorithm")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Algorithm", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-SignedHeaders", valid_611394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611396: Call_GetApp_611384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_611396.validator(path, query, header, formData, body)
  let scheme = call_611396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611396.url(scheme.get, call_611396.host, call_611396.base,
                         call_611396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611396, url, valid)

proc call*(call_611397: Call_GetApp_611384; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_611398 = newJObject()
  if body != nil:
    body_611398 = body
  result = call_611397.call(nil, nil, nil, nil, body_611398)

var getApp* = Call_GetApp_611384(name: "getApp", meth: HttpMethod.HttpPost,
                              host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                              validator: validate_GetApp_611385, base: "/",
                              url: url_GetApp_611386,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_611399 = ref object of OpenApiRestCall_610642
proc url_GetAppLaunchConfiguration_611401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppLaunchConfiguration_611400(path: JsonNode; query: JsonNode;
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
  var valid_611402 = header.getOrDefault("X-Amz-Target")
  valid_611402 = validateParameter(valid_611402, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_611402 != nil:
    section.add "X-Amz-Target", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Signature")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Signature", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Content-Sha256", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Date")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Date", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Credential")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Credential", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Security-Token")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Security-Token", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Algorithm")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Algorithm", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-SignedHeaders", valid_611409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611411: Call_GetAppLaunchConfiguration_611399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  let valid = call_611411.validator(path, query, header, formData, body)
  let scheme = call_611411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611411.url(scheme.get, call_611411.host, call_611411.base,
                         call_611411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611411, url, valid)

proc call*(call_611412: Call_GetAppLaunchConfiguration_611399; body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   body: JObject (required)
  var body_611413 = newJObject()
  if body != nil:
    body_611413 = body
  result = call_611412.call(nil, nil, nil, nil, body_611413)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_611399(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_611400, base: "/",
    url: url_GetAppLaunchConfiguration_611401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_611414 = ref object of OpenApiRestCall_610642
proc url_GetAppReplicationConfiguration_611416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppReplicationConfiguration_611415(path: JsonNode;
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
  var valid_611417 = header.getOrDefault("X-Amz-Target")
  valid_611417 = validateParameter(valid_611417, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_611417 != nil:
    section.add "X-Amz-Target", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Signature")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Signature", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Content-Sha256", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Date")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Date", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Credential")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Credential", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Security-Token")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Security-Token", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Algorithm")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Algorithm", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-SignedHeaders", valid_611424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611426: Call_GetAppReplicationConfiguration_611414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  let valid = call_611426.validator(path, query, header, formData, body)
  let scheme = call_611426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611426.url(scheme.get, call_611426.host, call_611426.base,
                         call_611426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611426, url, valid)

proc call*(call_611427: Call_GetAppReplicationConfiguration_611414; body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   body: JObject (required)
  var body_611428 = newJObject()
  if body != nil:
    body_611428 = body
  result = call_611427.call(nil, nil, nil, nil, body_611428)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_611414(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_611415, base: "/",
    url: url_GetAppReplicationConfiguration_611416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_611429 = ref object of OpenApiRestCall_610642
proc url_GetConnectors_611431(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnectors_611430(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611432 = query.getOrDefault("nextToken")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "nextToken", valid_611432
  var valid_611433 = query.getOrDefault("maxResults")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "maxResults", valid_611433
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
  var valid_611434 = header.getOrDefault("X-Amz-Target")
  valid_611434 = validateParameter(valid_611434, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_611434 != nil:
    section.add "X-Amz-Target", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Signature")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Signature", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Content-Sha256", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Date")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Date", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Credential")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Credential", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Security-Token")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Security-Token", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Algorithm")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Algorithm", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-SignedHeaders", valid_611441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611443: Call_GetConnectors_611429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  let valid = call_611443.validator(path, query, header, formData, body)
  let scheme = call_611443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611443.url(scheme.get, call_611443.host, call_611443.base,
                         call_611443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611443, url, valid)

proc call*(call_611444: Call_GetConnectors_611429; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611445 = newJObject()
  var body_611446 = newJObject()
  add(query_611445, "nextToken", newJString(nextToken))
  if body != nil:
    body_611446 = body
  add(query_611445, "maxResults", newJString(maxResults))
  result = call_611444.call(nil, query_611445, nil, nil, body_611446)

var getConnectors* = Call_GetConnectors_611429(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_611430, base: "/", url: url_GetConnectors_611431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_611448 = ref object of OpenApiRestCall_610642
proc url_GetReplicationJobs_611450(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReplicationJobs_611449(path: JsonNode; query: JsonNode;
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
  var valid_611451 = query.getOrDefault("nextToken")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "nextToken", valid_611451
  var valid_611452 = query.getOrDefault("maxResults")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "maxResults", valid_611452
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
  var valid_611453 = header.getOrDefault("X-Amz-Target")
  valid_611453 = validateParameter(valid_611453, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_611453 != nil:
    section.add "X-Amz-Target", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Signature")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Signature", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Content-Sha256", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Date")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Date", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Credential")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Credential", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Security-Token")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Security-Token", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Algorithm")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Algorithm", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-SignedHeaders", valid_611460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611462: Call_GetReplicationJobs_611448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  let valid = call_611462.validator(path, query, header, formData, body)
  let scheme = call_611462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611462.url(scheme.get, call_611462.host, call_611462.base,
                         call_611462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611462, url, valid)

proc call*(call_611463: Call_GetReplicationJobs_611448; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611464 = newJObject()
  var body_611465 = newJObject()
  add(query_611464, "nextToken", newJString(nextToken))
  if body != nil:
    body_611465 = body
  add(query_611464, "maxResults", newJString(maxResults))
  result = call_611463.call(nil, query_611464, nil, nil, body_611465)

var getReplicationJobs* = Call_GetReplicationJobs_611448(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_611449, base: "/",
    url: url_GetReplicationJobs_611450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_611466 = ref object of OpenApiRestCall_610642
proc url_GetReplicationRuns_611468(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReplicationRuns_611467(path: JsonNode; query: JsonNode;
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
  var valid_611469 = query.getOrDefault("nextToken")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "nextToken", valid_611469
  var valid_611470 = query.getOrDefault("maxResults")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "maxResults", valid_611470
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
  var valid_611471 = header.getOrDefault("X-Amz-Target")
  valid_611471 = validateParameter(valid_611471, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_611471 != nil:
    section.add "X-Amz-Target", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Signature")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Signature", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Content-Sha256", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Date")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Date", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Credential")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Credential", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Security-Token")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Security-Token", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Algorithm")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Algorithm", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-SignedHeaders", valid_611478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611480: Call_GetReplicationRuns_611466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the replication runs for the specified replication job.
  ## 
  let valid = call_611480.validator(path, query, header, formData, body)
  let scheme = call_611480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611480.url(scheme.get, call_611480.host, call_611480.base,
                         call_611480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611480, url, valid)

proc call*(call_611481: Call_GetReplicationRuns_611466; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611482 = newJObject()
  var body_611483 = newJObject()
  add(query_611482, "nextToken", newJString(nextToken))
  if body != nil:
    body_611483 = body
  add(query_611482, "maxResults", newJString(maxResults))
  result = call_611481.call(nil, query_611482, nil, nil, body_611483)

var getReplicationRuns* = Call_GetReplicationRuns_611466(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_611467, base: "/",
    url: url_GetReplicationRuns_611468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_611484 = ref object of OpenApiRestCall_610642
proc url_GetServers_611486(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServers_611485(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611487 = query.getOrDefault("nextToken")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "nextToken", valid_611487
  var valid_611488 = query.getOrDefault("maxResults")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "maxResults", valid_611488
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
  var valid_611489 = header.getOrDefault("X-Amz-Target")
  valid_611489 = validateParameter(valid_611489, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_611489 != nil:
    section.add "X-Amz-Target", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Signature")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Signature", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Content-Sha256", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Date")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Date", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Credential")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Credential", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Security-Token")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Security-Token", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Algorithm")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Algorithm", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-SignedHeaders", valid_611496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611498: Call_GetServers_611484; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  let valid = call_611498.validator(path, query, header, formData, body)
  let scheme = call_611498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611498.url(scheme.get, call_611498.host, call_611498.base,
                         call_611498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611498, url, valid)

proc call*(call_611499: Call_GetServers_611484; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611500 = newJObject()
  var body_611501 = newJObject()
  add(query_611500, "nextToken", newJString(nextToken))
  if body != nil:
    body_611501 = body
  add(query_611500, "maxResults", newJString(maxResults))
  result = call_611499.call(nil, query_611500, nil, nil, body_611501)

var getServers* = Call_GetServers_611484(name: "getServers",
                                      meth: HttpMethod.HttpPost,
                                      host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
                                      validator: validate_GetServers_611485,
                                      base: "/", url: url_GetServers_611486,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_611502 = ref object of OpenApiRestCall_610642
proc url_ImportServerCatalog_611504(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportServerCatalog_611503(path: JsonNode; query: JsonNode;
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
  var valid_611505 = header.getOrDefault("X-Amz-Target")
  valid_611505 = validateParameter(valid_611505, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_611505 != nil:
    section.add "X-Amz-Target", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Signature")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Signature", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Content-Sha256", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Date")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Date", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Credential")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Credential", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Security-Token")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Security-Token", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Algorithm")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Algorithm", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-SignedHeaders", valid_611512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611514: Call_ImportServerCatalog_611502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  let valid = call_611514.validator(path, query, header, formData, body)
  let scheme = call_611514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611514.url(scheme.get, call_611514.host, call_611514.base,
                         call_611514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611514, url, valid)

proc call*(call_611515: Call_ImportServerCatalog_611502; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   body: JObject (required)
  var body_611516 = newJObject()
  if body != nil:
    body_611516 = body
  result = call_611515.call(nil, nil, nil, nil, body_611516)

var importServerCatalog* = Call_ImportServerCatalog_611502(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_611503, base: "/",
    url: url_ImportServerCatalog_611504, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_611517 = ref object of OpenApiRestCall_610642
proc url_LaunchApp_611519(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LaunchApp_611518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611520 = header.getOrDefault("X-Amz-Target")
  valid_611520 = validateParameter(valid_611520, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_611520 != nil:
    section.add "X-Amz-Target", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Signature")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Signature", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Content-Sha256", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Date")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Date", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Credential")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Credential", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Security-Token")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Security-Token", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Algorithm")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Algorithm", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-SignedHeaders", valid_611527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611529: Call_LaunchApp_611517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an application stack.
  ## 
  let valid = call_611529.validator(path, query, header, formData, body)
  let scheme = call_611529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611529.url(scheme.get, call_611529.host, call_611529.base,
                         call_611529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611529, url, valid)

proc call*(call_611530: Call_LaunchApp_611517; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_611531 = newJObject()
  if body != nil:
    body_611531 = body
  result = call_611530.call(nil, nil, nil, nil, body_611531)

var launchApp* = Call_LaunchApp_611517(name: "launchApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
                                    validator: validate_LaunchApp_611518,
                                    base: "/", url: url_LaunchApp_611519,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_611532 = ref object of OpenApiRestCall_610642
proc url_ListApps_611534(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_611533(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611535 = header.getOrDefault("X-Amz-Target")
  valid_611535 = validateParameter(valid_611535, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_611535 != nil:
    section.add "X-Amz-Target", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Signature")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Signature", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Content-Sha256", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Date")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Date", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Credential")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Credential", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Security-Token")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Security-Token", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Algorithm")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Algorithm", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-SignedHeaders", valid_611542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611544: Call_ListApps_611532; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of summaries for all applications.
  ## 
  let valid = call_611544.validator(path, query, header, formData, body)
  let scheme = call_611544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611544.url(scheme.get, call_611544.host, call_611544.base,
                         call_611544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611544, url, valid)

proc call*(call_611545: Call_ListApps_611532; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_611546 = newJObject()
  if body != nil:
    body_611546 = body
  result = call_611545.call(nil, nil, nil, nil, body_611546)

var listApps* = Call_ListApps_611532(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                  validator: validate_ListApps_611533, base: "/",
                                  url: url_ListApps_611534,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_611547 = ref object of OpenApiRestCall_610642
proc url_PutAppLaunchConfiguration_611549(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppLaunchConfiguration_611548(path: JsonNode; query: JsonNode;
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
  var valid_611550 = header.getOrDefault("X-Amz-Target")
  valid_611550 = validateParameter(valid_611550, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_611550 != nil:
    section.add "X-Amz-Target", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Signature")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Signature", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Content-Sha256", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Date")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Date", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Credential")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Credential", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Security-Token")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Security-Token", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Algorithm")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Algorithm", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-SignedHeaders", valid_611557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611559: Call_PutAppLaunchConfiguration_611547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a launch configuration for an application.
  ## 
  let valid = call_611559.validator(path, query, header, formData, body)
  let scheme = call_611559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611559.url(scheme.get, call_611559.host, call_611559.base,
                         call_611559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611559, url, valid)

proc call*(call_611560: Call_PutAppLaunchConfiguration_611547; body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_611561 = newJObject()
  if body != nil:
    body_611561 = body
  result = call_611560.call(nil, nil, nil, nil, body_611561)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_611547(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_611548, base: "/",
    url: url_PutAppLaunchConfiguration_611549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_611562 = ref object of OpenApiRestCall_610642
proc url_PutAppReplicationConfiguration_611564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppReplicationConfiguration_611563(path: JsonNode;
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
  var valid_611565 = header.getOrDefault("X-Amz-Target")
  valid_611565 = validateParameter(valid_611565, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_611565 != nil:
    section.add "X-Amz-Target", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Signature")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Signature", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Content-Sha256", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Date")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Date", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Credential")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Credential", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Security-Token")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Security-Token", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Algorithm")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Algorithm", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-SignedHeaders", valid_611572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611574: Call_PutAppReplicationConfiguration_611562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a replication configuration for an application.
  ## 
  let valid = call_611574.validator(path, query, header, formData, body)
  let scheme = call_611574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611574.url(scheme.get, call_611574.host, call_611574.base,
                         call_611574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611574, url, valid)

proc call*(call_611575: Call_PutAppReplicationConfiguration_611562; body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject (required)
  var body_611576 = newJObject()
  if body != nil:
    body_611576 = body
  result = call_611575.call(nil, nil, nil, nil, body_611576)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_611562(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_611563, base: "/",
    url: url_PutAppReplicationConfiguration_611564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_611577 = ref object of OpenApiRestCall_610642
proc url_StartAppReplication_611579(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAppReplication_611578(path: JsonNode; query: JsonNode;
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
  var valid_611580 = header.getOrDefault("X-Amz-Target")
  valid_611580 = validateParameter(valid_611580, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_611580 != nil:
    section.add "X-Amz-Target", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Signature")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Signature", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Content-Sha256", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Date")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Date", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Credential")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Credential", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Security-Token")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Security-Token", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Algorithm")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Algorithm", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-SignedHeaders", valid_611587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611589: Call_StartAppReplication_611577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts replicating an application.
  ## 
  let valid = call_611589.validator(path, query, header, formData, body)
  let scheme = call_611589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611589.url(scheme.get, call_611589.host, call_611589.base,
                         call_611589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611589, url, valid)

proc call*(call_611590: Call_StartAppReplication_611577; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_611591 = newJObject()
  if body != nil:
    body_611591 = body
  result = call_611590.call(nil, nil, nil, nil, body_611591)

var startAppReplication* = Call_StartAppReplication_611577(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_611578, base: "/",
    url: url_StartAppReplication_611579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_611592 = ref object of OpenApiRestCall_610642
proc url_StartOnDemandReplicationRun_611594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartOnDemandReplicationRun_611593(path: JsonNode; query: JsonNode;
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
  var valid_611595 = header.getOrDefault("X-Amz-Target")
  valid_611595 = validateParameter(valid_611595, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_611595 != nil:
    section.add "X-Amz-Target", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-Signature")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Signature", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Content-Sha256", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Date")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Date", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Credential")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Credential", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Security-Token")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Security-Token", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Algorithm")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Algorithm", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-SignedHeaders", valid_611602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611604: Call_StartOnDemandReplicationRun_611592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  let valid = call_611604.validator(path, query, header, formData, body)
  let scheme = call_611604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611604.url(scheme.get, call_611604.host, call_611604.base,
                         call_611604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611604, url, valid)

proc call*(call_611605: Call_StartOnDemandReplicationRun_611592; body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_611606 = newJObject()
  if body != nil:
    body_611606 = body
  result = call_611605.call(nil, nil, nil, nil, body_611606)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_611592(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_611593, base: "/",
    url: url_StartOnDemandReplicationRun_611594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_611607 = ref object of OpenApiRestCall_610642
proc url_StopAppReplication_611609(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAppReplication_611608(path: JsonNode; query: JsonNode;
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
  var valid_611610 = header.getOrDefault("X-Amz-Target")
  valid_611610 = validateParameter(valid_611610, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_611610 != nil:
    section.add "X-Amz-Target", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Signature")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Signature", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Content-Sha256", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Date")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Date", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Credential")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Credential", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Security-Token")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Security-Token", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Algorithm")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Algorithm", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-SignedHeaders", valid_611617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611619: Call_StopAppReplication_611607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops replicating an application.
  ## 
  let valid = call_611619.validator(path, query, header, formData, body)
  let scheme = call_611619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611619.url(scheme.get, call_611619.host, call_611619.base,
                         call_611619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611619, url, valid)

proc call*(call_611620: Call_StopAppReplication_611607; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_611621 = newJObject()
  if body != nil:
    body_611621 = body
  result = call_611620.call(nil, nil, nil, nil, body_611621)

var stopAppReplication* = Call_StopAppReplication_611607(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_611608, base: "/",
    url: url_StopAppReplication_611609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_611622 = ref object of OpenApiRestCall_610642
proc url_TerminateApp_611624(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateApp_611623(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611625 = header.getOrDefault("X-Amz-Target")
  valid_611625 = validateParameter(valid_611625, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_611625 != nil:
    section.add "X-Amz-Target", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Signature")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Signature", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Content-Sha256", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Date")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Date", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Credential")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Credential", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Security-Token")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Security-Token", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Algorithm")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Algorithm", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-SignedHeaders", valid_611632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611634: Call_TerminateApp_611622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the stack for an application.
  ## 
  let valid = call_611634.validator(path, query, header, formData, body)
  let scheme = call_611634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611634.url(scheme.get, call_611634.host, call_611634.base,
                         call_611634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611634, url, valid)

proc call*(call_611635: Call_TerminateApp_611622; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_611636 = newJObject()
  if body != nil:
    body_611636 = body
  result = call_611635.call(nil, nil, nil, nil, body_611636)

var terminateApp* = Call_TerminateApp_611622(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_611623, base: "/", url: url_TerminateApp_611624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_611637 = ref object of OpenApiRestCall_610642
proc url_UpdateApp_611639(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApp_611638(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611640 = header.getOrDefault("X-Amz-Target")
  valid_611640 = validateParameter(valid_611640, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_611640 != nil:
    section.add "X-Amz-Target", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Signature")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Signature", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Content-Sha256", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Date")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Date", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Credential")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Credential", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Security-Token")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Security-Token", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Algorithm")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Algorithm", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-SignedHeaders", valid_611647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611649: Call_UpdateApp_611637; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_611649.validator(path, query, header, formData, body)
  let scheme = call_611649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611649.url(scheme.get, call_611649.host, call_611649.base,
                         call_611649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611649, url, valid)

proc call*(call_611650: Call_UpdateApp_611637; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_611651 = newJObject()
  if body != nil:
    body_611651 = body
  result = call_611650.call(nil, nil, nil, nil, body_611651)

var updateApp* = Call_UpdateApp_611637(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
                                    validator: validate_UpdateApp_611638,
                                    base: "/", url: url_UpdateApp_611639,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_611652 = ref object of OpenApiRestCall_610642
proc url_UpdateReplicationJob_611654(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateReplicationJob_611653(path: JsonNode; query: JsonNode;
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
  var valid_611655 = header.getOrDefault("X-Amz-Target")
  valid_611655 = validateParameter(valid_611655, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_611655 != nil:
    section.add "X-Amz-Target", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Signature")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Signature", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Content-Sha256", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Date")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Date", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Credential")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Credential", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Security-Token")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Security-Token", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Algorithm")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Algorithm", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-SignedHeaders", valid_611662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611664: Call_UpdateReplicationJob_611652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified settings for the specified replication job.
  ## 
  let valid = call_611664.validator(path, query, header, formData, body)
  let scheme = call_611664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611664.url(scheme.get, call_611664.host, call_611664.base,
                         call_611664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611664, url, valid)

proc call*(call_611665: Call_UpdateReplicationJob_611652; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_611666 = newJObject()
  if body != nil:
    body_611666 = body
  result = call_611665.call(nil, nil, nil, nil, body_611666)

var updateReplicationJob* = Call_UpdateReplicationJob_611652(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_611653, base: "/",
    url: url_UpdateReplicationJob_611654, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
