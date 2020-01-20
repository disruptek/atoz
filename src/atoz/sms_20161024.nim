
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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
  Call_CreateApp_605911 = ref object of OpenApiRestCall_605573
proc url_CreateApp_605913(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_605912(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606038 = header.getOrDefault("X-Amz-Target")
  valid_606038 = validateParameter(valid_606038, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_606038 != nil:
    section.add "X-Amz-Target", valid_606038
  var valid_606039 = header.getOrDefault("X-Amz-Signature")
  valid_606039 = validateParameter(valid_606039, JString, required = false,
                                 default = nil)
  if valid_606039 != nil:
    section.add "X-Amz-Signature", valid_606039
  var valid_606040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606040 = validateParameter(valid_606040, JString, required = false,
                                 default = nil)
  if valid_606040 != nil:
    section.add "X-Amz-Content-Sha256", valid_606040
  var valid_606041 = header.getOrDefault("X-Amz-Date")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Date", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Credential")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Credential", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Security-Token")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Security-Token", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Algorithm")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Algorithm", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-SignedHeaders", valid_606045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606069: Call_CreateApp_605911; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  let valid = call_606069.validator(path, query, header, formData, body)
  let scheme = call_606069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606069.url(scheme.get, call_606069.host, call_606069.base,
                         call_606069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606069, url, valid)

proc call*(call_606140: Call_CreateApp_605911; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   body: JObject (required)
  var body_606141 = newJObject()
  if body != nil:
    body_606141 = body
  result = call_606140.call(nil, nil, nil, nil, body_606141)

var createApp* = Call_CreateApp_605911(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
                                    validator: validate_CreateApp_605912,
                                    base: "/", url: url_CreateApp_605913,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_606180 = ref object of OpenApiRestCall_605573
proc url_CreateReplicationJob_606182(protocol: Scheme; host: string; base: string;
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

proc validate_CreateReplicationJob_606181(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606183 = header.getOrDefault("X-Amz-Target")
  valid_606183 = validateParameter(valid_606183, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_606183 != nil:
    section.add "X-Amz-Target", valid_606183
  var valid_606184 = header.getOrDefault("X-Amz-Signature")
  valid_606184 = validateParameter(valid_606184, JString, required = false,
                                 default = nil)
  if valid_606184 != nil:
    section.add "X-Amz-Signature", valid_606184
  var valid_606185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Content-Sha256", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Date")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Date", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Credential")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Credential", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-Security-Token")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Security-Token", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Algorithm")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Algorithm", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-SignedHeaders", valid_606190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606192: Call_CreateReplicationJob_606180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  let valid = call_606192.validator(path, query, header, formData, body)
  let scheme = call_606192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606192.url(scheme.get, call_606192.host, call_606192.base,
                         call_606192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606192, url, valid)

proc call*(call_606193: Call_CreateReplicationJob_606180; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   body: JObject (required)
  var body_606194 = newJObject()
  if body != nil:
    body_606194 = body
  result = call_606193.call(nil, nil, nil, nil, body_606194)

var createReplicationJob* = Call_CreateReplicationJob_606180(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_606181, base: "/",
    url: url_CreateReplicationJob_606182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_606195 = ref object of OpenApiRestCall_605573
proc url_DeleteApp_606197(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_606196(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606198 = header.getOrDefault("X-Amz-Target")
  valid_606198 = validateParameter(valid_606198, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_606198 != nil:
    section.add "X-Amz-Target", valid_606198
  var valid_606199 = header.getOrDefault("X-Amz-Signature")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "X-Amz-Signature", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Content-Sha256", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Date")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Date", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Credential")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Credential", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Security-Token")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Security-Token", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Algorithm")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Algorithm", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-SignedHeaders", valid_606205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606207: Call_DeleteApp_606195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  let valid = call_606207.validator(path, query, header, formData, body)
  let scheme = call_606207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606207.url(scheme.get, call_606207.host, call_606207.base,
                         call_606207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606207, url, valid)

proc call*(call_606208: Call_DeleteApp_606195; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   body: JObject (required)
  var body_606209 = newJObject()
  if body != nil:
    body_606209 = body
  result = call_606208.call(nil, nil, nil, nil, body_606209)

var deleteApp* = Call_DeleteApp_606195(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
                                    validator: validate_DeleteApp_606196,
                                    base: "/", url: url_DeleteApp_606197,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_606210 = ref object of OpenApiRestCall_605573
proc url_DeleteAppLaunchConfiguration_606212(protocol: Scheme; host: string;
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

proc validate_DeleteAppLaunchConfiguration_606211(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606213 = header.getOrDefault("X-Amz-Target")
  valid_606213 = validateParameter(valid_606213, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_606213 != nil:
    section.add "X-Amz-Target", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Signature")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Signature", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Content-Sha256", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Date")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Date", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Credential")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Credential", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Security-Token")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Security-Token", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Algorithm")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Algorithm", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-SignedHeaders", valid_606220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606222: Call_DeleteAppLaunchConfiguration_606210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes existing launch configuration for an application.
  ## 
  let valid = call_606222.validator(path, query, header, formData, body)
  let scheme = call_606222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606222.url(scheme.get, call_606222.host, call_606222.base,
                         call_606222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606222, url, valid)

proc call*(call_606223: Call_DeleteAppLaunchConfiguration_606210; body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_606224 = newJObject()
  if body != nil:
    body_606224 = body
  result = call_606223.call(nil, nil, nil, nil, body_606224)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_606210(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_606211, base: "/",
    url: url_DeleteAppLaunchConfiguration_606212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_606225 = ref object of OpenApiRestCall_605573
proc url_DeleteAppReplicationConfiguration_606227(protocol: Scheme; host: string;
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

proc validate_DeleteAppReplicationConfiguration_606226(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606228 = header.getOrDefault("X-Amz-Target")
  valid_606228 = validateParameter(valid_606228, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_606228 != nil:
    section.add "X-Amz-Target", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Signature")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Signature", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Content-Sha256", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Date")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Date", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Credential")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Credential", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Security-Token")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Security-Token", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Algorithm")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Algorithm", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-SignedHeaders", valid_606235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606237: Call_DeleteAppReplicationConfiguration_606225;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes existing replication configuration for an application.
  ## 
  let valid = call_606237.validator(path, query, header, formData, body)
  let scheme = call_606237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606237.url(scheme.get, call_606237.host, call_606237.base,
                         call_606237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606237, url, valid)

proc call*(call_606238: Call_DeleteAppReplicationConfiguration_606225;
          body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_606239 = newJObject()
  if body != nil:
    body_606239 = body
  result = call_606238.call(nil, nil, nil, nil, body_606239)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_606225(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_606226, base: "/",
    url: url_DeleteAppReplicationConfiguration_606227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_606240 = ref object of OpenApiRestCall_605573
proc url_DeleteReplicationJob_606242(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReplicationJob_606241(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606243 = header.getOrDefault("X-Amz-Target")
  valid_606243 = validateParameter(valid_606243, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_606243 != nil:
    section.add "X-Amz-Target", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Signature")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Signature", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Content-Sha256", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Date")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Date", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Credential")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Credential", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Security-Token")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Security-Token", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Algorithm")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Algorithm", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-SignedHeaders", valid_606250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606252: Call_DeleteReplicationJob_606240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  let valid = call_606252.validator(path, query, header, formData, body)
  let scheme = call_606252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606252.url(scheme.get, call_606252.host, call_606252.base,
                         call_606252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606252, url, valid)

proc call*(call_606253: Call_DeleteReplicationJob_606240; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   body: JObject (required)
  var body_606254 = newJObject()
  if body != nil:
    body_606254 = body
  result = call_606253.call(nil, nil, nil, nil, body_606254)

var deleteReplicationJob* = Call_DeleteReplicationJob_606240(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_606241, base: "/",
    url: url_DeleteReplicationJob_606242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_606255 = ref object of OpenApiRestCall_605573
proc url_DeleteServerCatalog_606257(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteServerCatalog_606256(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606258 = header.getOrDefault("X-Amz-Target")
  valid_606258 = validateParameter(valid_606258, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_606258 != nil:
    section.add "X-Amz-Target", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Signature")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Signature", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Content-Sha256", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Date")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Date", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Credential")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Credential", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Security-Token")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Security-Token", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Algorithm")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Algorithm", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-SignedHeaders", valid_606265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606267: Call_DeleteServerCatalog_606255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all servers from your server catalog.
  ## 
  let valid = call_606267.validator(path, query, header, formData, body)
  let scheme = call_606267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606267.url(scheme.get, call_606267.host, call_606267.base,
                         call_606267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606267, url, valid)

proc call*(call_606268: Call_DeleteServerCatalog_606255; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_606269 = newJObject()
  if body != nil:
    body_606269 = body
  result = call_606268.call(nil, nil, nil, nil, body_606269)

var deleteServerCatalog* = Call_DeleteServerCatalog_606255(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_606256, base: "/",
    url: url_DeleteServerCatalog_606257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_606270 = ref object of OpenApiRestCall_605573
proc url_DisassociateConnector_606272(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateConnector_606271(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606273 = header.getOrDefault("X-Amz-Target")
  valid_606273 = validateParameter(valid_606273, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_606273 != nil:
    section.add "X-Amz-Target", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Signature")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Signature", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Content-Sha256", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Date")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Date", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Credential")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Credential", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Security-Token")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Security-Token", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Algorithm")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Algorithm", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-SignedHeaders", valid_606280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606282: Call_DisassociateConnector_606270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  let valid = call_606282.validator(path, query, header, formData, body)
  let scheme = call_606282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606282.url(scheme.get, call_606282.host, call_606282.base,
                         call_606282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606282, url, valid)

proc call*(call_606283: Call_DisassociateConnector_606270; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   body: JObject (required)
  var body_606284 = newJObject()
  if body != nil:
    body_606284 = body
  result = call_606283.call(nil, nil, nil, nil, body_606284)

var disassociateConnector* = Call_DisassociateConnector_606270(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_606271, base: "/",
    url: url_DisassociateConnector_606272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_606285 = ref object of OpenApiRestCall_605573
proc url_GenerateChangeSet_606287(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateChangeSet_606286(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606288 = header.getOrDefault("X-Amz-Target")
  valid_606288 = validateParameter(valid_606288, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_606288 != nil:
    section.add "X-Amz-Target", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Signature")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Signature", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Content-Sha256", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Date")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Date", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Credential")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Credential", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Security-Token")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Security-Token", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Algorithm")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Algorithm", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-SignedHeaders", valid_606295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606297: Call_GenerateChangeSet_606285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_606297.validator(path, query, header, formData, body)
  let scheme = call_606297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606297.url(scheme.get, call_606297.host, call_606297.base,
                         call_606297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606297, url, valid)

proc call*(call_606298: Call_GenerateChangeSet_606285; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_606299 = newJObject()
  if body != nil:
    body_606299 = body
  result = call_606298.call(nil, nil, nil, nil, body_606299)

var generateChangeSet* = Call_GenerateChangeSet_606285(name: "generateChangeSet",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_606286, base: "/",
    url: url_GenerateChangeSet_606287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_606300 = ref object of OpenApiRestCall_605573
proc url_GenerateTemplate_606302(protocol: Scheme; host: string; base: string;
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

proc validate_GenerateTemplate_606301(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606303 = header.getOrDefault("X-Amz-Target")
  valid_606303 = validateParameter(valid_606303, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_606303 != nil:
    section.add "X-Amz-Target", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Signature")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Signature", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Content-Sha256", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Date")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Date", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Credential")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Credential", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Security-Token")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Security-Token", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Algorithm")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Algorithm", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-SignedHeaders", valid_606310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606312: Call_GenerateTemplate_606300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_606312.validator(path, query, header, formData, body)
  let scheme = call_606312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606312.url(scheme.get, call_606312.host, call_606312.base,
                         call_606312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606312, url, valid)

proc call*(call_606313: Call_GenerateTemplate_606300; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_606314 = newJObject()
  if body != nil:
    body_606314 = body
  result = call_606313.call(nil, nil, nil, nil, body_606314)

var generateTemplate* = Call_GenerateTemplate_606300(name: "generateTemplate",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_606301, base: "/",
    url: url_GenerateTemplate_606302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_606315 = ref object of OpenApiRestCall_605573
proc url_GetApp_606317(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetApp_606316(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606318 = header.getOrDefault("X-Amz-Target")
  valid_606318 = validateParameter(valid_606318, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_606318 != nil:
    section.add "X-Amz-Target", valid_606318
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606327: Call_GetApp_606315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_606327.validator(path, query, header, formData, body)
  let scheme = call_606327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606327.url(scheme.get, call_606327.host, call_606327.base,
                         call_606327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606327, url, valid)

proc call*(call_606328: Call_GetApp_606315; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_606329 = newJObject()
  if body != nil:
    body_606329 = body
  result = call_606328.call(nil, nil, nil, nil, body_606329)

var getApp* = Call_GetApp_606315(name: "getApp", meth: HttpMethod.HttpPost,
                              host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                              validator: validate_GetApp_606316, base: "/",
                              url: url_GetApp_606317,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_606330 = ref object of OpenApiRestCall_605573
proc url_GetAppLaunchConfiguration_606332(protocol: Scheme; host: string;
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

proc validate_GetAppLaunchConfiguration_606331(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606333 = header.getOrDefault("X-Amz-Target")
  valid_606333 = validateParameter(valid_606333, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_606333 != nil:
    section.add "X-Amz-Target", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Signature")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Signature", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Content-Sha256", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Date")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Date", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Credential")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Credential", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Security-Token")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Security-Token", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Algorithm")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Algorithm", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-SignedHeaders", valid_606340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606342: Call_GetAppLaunchConfiguration_606330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  let valid = call_606342.validator(path, query, header, formData, body)
  let scheme = call_606342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606342.url(scheme.get, call_606342.host, call_606342.base,
                         call_606342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606342, url, valid)

proc call*(call_606343: Call_GetAppLaunchConfiguration_606330; body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   body: JObject (required)
  var body_606344 = newJObject()
  if body != nil:
    body_606344 = body
  result = call_606343.call(nil, nil, nil, nil, body_606344)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_606330(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_606331, base: "/",
    url: url_GetAppLaunchConfiguration_606332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_606345 = ref object of OpenApiRestCall_605573
proc url_GetAppReplicationConfiguration_606347(protocol: Scheme; host: string;
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

proc validate_GetAppReplicationConfiguration_606346(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606348 = header.getOrDefault("X-Amz-Target")
  valid_606348 = validateParameter(valid_606348, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_606348 != nil:
    section.add "X-Amz-Target", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Signature")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Signature", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Content-Sha256", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Date")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Date", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Credential")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Credential", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Security-Token")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Security-Token", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Algorithm")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Algorithm", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-SignedHeaders", valid_606355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606357: Call_GetAppReplicationConfiguration_606345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  let valid = call_606357.validator(path, query, header, formData, body)
  let scheme = call_606357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606357.url(scheme.get, call_606357.host, call_606357.base,
                         call_606357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606357, url, valid)

proc call*(call_606358: Call_GetAppReplicationConfiguration_606345; body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   body: JObject (required)
  var body_606359 = newJObject()
  if body != nil:
    body_606359 = body
  result = call_606358.call(nil, nil, nil, nil, body_606359)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_606345(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_606346, base: "/",
    url: url_GetAppReplicationConfiguration_606347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_606360 = ref object of OpenApiRestCall_605573
proc url_GetConnectors_606362(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnectors_606361(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606363 = query.getOrDefault("nextToken")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "nextToken", valid_606363
  var valid_606364 = query.getOrDefault("maxResults")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "maxResults", valid_606364
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606365 = header.getOrDefault("X-Amz-Target")
  valid_606365 = validateParameter(valid_606365, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_606365 != nil:
    section.add "X-Amz-Target", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Signature")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Signature", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Content-Sha256", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Date")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Date", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Credential")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Credential", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Security-Token")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Security-Token", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Algorithm")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Algorithm", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-SignedHeaders", valid_606372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606374: Call_GetConnectors_606360; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  let valid = call_606374.validator(path, query, header, formData, body)
  let scheme = call_606374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606374.url(scheme.get, call_606374.host, call_606374.base,
                         call_606374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606374, url, valid)

proc call*(call_606375: Call_GetConnectors_606360; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606376 = newJObject()
  var body_606377 = newJObject()
  add(query_606376, "nextToken", newJString(nextToken))
  if body != nil:
    body_606377 = body
  add(query_606376, "maxResults", newJString(maxResults))
  result = call_606375.call(nil, query_606376, nil, nil, body_606377)

var getConnectors* = Call_GetConnectors_606360(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_606361, base: "/", url: url_GetConnectors_606362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_606379 = ref object of OpenApiRestCall_605573
proc url_GetReplicationJobs_606381(protocol: Scheme; host: string; base: string;
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

proc validate_GetReplicationJobs_606380(path: JsonNode; query: JsonNode;
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
  var valid_606382 = query.getOrDefault("nextToken")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "nextToken", valid_606382
  var valid_606383 = query.getOrDefault("maxResults")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "maxResults", valid_606383
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606384 = header.getOrDefault("X-Amz-Target")
  valid_606384 = validateParameter(valid_606384, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_606384 != nil:
    section.add "X-Amz-Target", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Signature")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Signature", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Content-Sha256", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Date")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Date", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Credential")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Credential", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Security-Token")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Security-Token", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Algorithm")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Algorithm", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-SignedHeaders", valid_606391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606393: Call_GetReplicationJobs_606379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  let valid = call_606393.validator(path, query, header, formData, body)
  let scheme = call_606393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606393.url(scheme.get, call_606393.host, call_606393.base,
                         call_606393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606393, url, valid)

proc call*(call_606394: Call_GetReplicationJobs_606379; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606395 = newJObject()
  var body_606396 = newJObject()
  add(query_606395, "nextToken", newJString(nextToken))
  if body != nil:
    body_606396 = body
  add(query_606395, "maxResults", newJString(maxResults))
  result = call_606394.call(nil, query_606395, nil, nil, body_606396)

var getReplicationJobs* = Call_GetReplicationJobs_606379(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_606380, base: "/",
    url: url_GetReplicationJobs_606381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_606397 = ref object of OpenApiRestCall_605573
proc url_GetReplicationRuns_606399(protocol: Scheme; host: string; base: string;
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

proc validate_GetReplicationRuns_606398(path: JsonNode; query: JsonNode;
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
  var valid_606400 = query.getOrDefault("nextToken")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "nextToken", valid_606400
  var valid_606401 = query.getOrDefault("maxResults")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "maxResults", valid_606401
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606402 = header.getOrDefault("X-Amz-Target")
  valid_606402 = validateParameter(valid_606402, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_606402 != nil:
    section.add "X-Amz-Target", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Signature")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Signature", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Content-Sha256", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Date")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Date", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Credential")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Credential", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Security-Token")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Security-Token", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Algorithm")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Algorithm", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-SignedHeaders", valid_606409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606411: Call_GetReplicationRuns_606397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the replication runs for the specified replication job.
  ## 
  let valid = call_606411.validator(path, query, header, formData, body)
  let scheme = call_606411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606411.url(scheme.get, call_606411.host, call_606411.base,
                         call_606411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606411, url, valid)

proc call*(call_606412: Call_GetReplicationRuns_606397; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606413 = newJObject()
  var body_606414 = newJObject()
  add(query_606413, "nextToken", newJString(nextToken))
  if body != nil:
    body_606414 = body
  add(query_606413, "maxResults", newJString(maxResults))
  result = call_606412.call(nil, query_606413, nil, nil, body_606414)

var getReplicationRuns* = Call_GetReplicationRuns_606397(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_606398, base: "/",
    url: url_GetReplicationRuns_606399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_606415 = ref object of OpenApiRestCall_605573
proc url_GetServers_606417(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetServers_606416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606418 = query.getOrDefault("nextToken")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "nextToken", valid_606418
  var valid_606419 = query.getOrDefault("maxResults")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "maxResults", valid_606419
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606420 = header.getOrDefault("X-Amz-Target")
  valid_606420 = validateParameter(valid_606420, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_606420 != nil:
    section.add "X-Amz-Target", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Signature")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Signature", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Content-Sha256", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Date")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Date", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Credential")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Credential", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Security-Token")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Security-Token", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Algorithm")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Algorithm", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-SignedHeaders", valid_606427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606429: Call_GetServers_606415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  let valid = call_606429.validator(path, query, header, formData, body)
  let scheme = call_606429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606429.url(scheme.get, call_606429.host, call_606429.base,
                         call_606429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606429, url, valid)

proc call*(call_606430: Call_GetServers_606415; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606431 = newJObject()
  var body_606432 = newJObject()
  add(query_606431, "nextToken", newJString(nextToken))
  if body != nil:
    body_606432 = body
  add(query_606431, "maxResults", newJString(maxResults))
  result = call_606430.call(nil, query_606431, nil, nil, body_606432)

var getServers* = Call_GetServers_606415(name: "getServers",
                                      meth: HttpMethod.HttpPost,
                                      host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
                                      validator: validate_GetServers_606416,
                                      base: "/", url: url_GetServers_606417,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_606433 = ref object of OpenApiRestCall_605573
proc url_ImportServerCatalog_606435(protocol: Scheme; host: string; base: string;
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

proc validate_ImportServerCatalog_606434(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606436 = header.getOrDefault("X-Amz-Target")
  valid_606436 = validateParameter(valid_606436, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_606436 != nil:
    section.add "X-Amz-Target", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Signature")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Signature", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Content-Sha256", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Date")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Date", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Credential")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Credential", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Security-Token")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Security-Token", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Algorithm")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Algorithm", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-SignedHeaders", valid_606443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606445: Call_ImportServerCatalog_606433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  let valid = call_606445.validator(path, query, header, formData, body)
  let scheme = call_606445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606445.url(scheme.get, call_606445.host, call_606445.base,
                         call_606445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606445, url, valid)

proc call*(call_606446: Call_ImportServerCatalog_606433; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   body: JObject (required)
  var body_606447 = newJObject()
  if body != nil:
    body_606447 = body
  result = call_606446.call(nil, nil, nil, nil, body_606447)

var importServerCatalog* = Call_ImportServerCatalog_606433(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_606434, base: "/",
    url: url_ImportServerCatalog_606435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_606448 = ref object of OpenApiRestCall_605573
proc url_LaunchApp_606450(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_LaunchApp_606449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606451 = header.getOrDefault("X-Amz-Target")
  valid_606451 = validateParameter(valid_606451, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_606451 != nil:
    section.add "X-Amz-Target", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Signature")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Signature", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Content-Sha256", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Date")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Date", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Credential")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Credential", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Security-Token")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Security-Token", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Algorithm")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Algorithm", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-SignedHeaders", valid_606458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606460: Call_LaunchApp_606448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an application stack.
  ## 
  let valid = call_606460.validator(path, query, header, formData, body)
  let scheme = call_606460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606460.url(scheme.get, call_606460.host, call_606460.base,
                         call_606460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606460, url, valid)

proc call*(call_606461: Call_LaunchApp_606448; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_606462 = newJObject()
  if body != nil:
    body_606462 = body
  result = call_606461.call(nil, nil, nil, nil, body_606462)

var launchApp* = Call_LaunchApp_606448(name: "launchApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
                                    validator: validate_LaunchApp_606449,
                                    base: "/", url: url_LaunchApp_606450,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_606463 = ref object of OpenApiRestCall_605573
proc url_ListApps_606465(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListApps_606464(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606466 = header.getOrDefault("X-Amz-Target")
  valid_606466 = validateParameter(valid_606466, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_606466 != nil:
    section.add "X-Amz-Target", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Signature")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Signature", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Content-Sha256", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Date")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Date", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Credential")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Credential", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Security-Token")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Security-Token", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Algorithm")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Algorithm", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-SignedHeaders", valid_606473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606475: Call_ListApps_606463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of summaries for all applications.
  ## 
  let valid = call_606475.validator(path, query, header, formData, body)
  let scheme = call_606475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606475.url(scheme.get, call_606475.host, call_606475.base,
                         call_606475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606475, url, valid)

proc call*(call_606476: Call_ListApps_606463; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_606477 = newJObject()
  if body != nil:
    body_606477 = body
  result = call_606476.call(nil, nil, nil, nil, body_606477)

var listApps* = Call_ListApps_606463(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                  validator: validate_ListApps_606464, base: "/",
                                  url: url_ListApps_606465,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_606478 = ref object of OpenApiRestCall_605573
proc url_PutAppLaunchConfiguration_606480(protocol: Scheme; host: string;
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

proc validate_PutAppLaunchConfiguration_606479(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606481 = header.getOrDefault("X-Amz-Target")
  valid_606481 = validateParameter(valid_606481, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_606481 != nil:
    section.add "X-Amz-Target", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Signature")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Signature", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Content-Sha256", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Date")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Date", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Credential")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Credential", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Security-Token")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Security-Token", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Algorithm")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Algorithm", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-SignedHeaders", valid_606488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606490: Call_PutAppLaunchConfiguration_606478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a launch configuration for an application.
  ## 
  let valid = call_606490.validator(path, query, header, formData, body)
  let scheme = call_606490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606490.url(scheme.get, call_606490.host, call_606490.base,
                         call_606490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606490, url, valid)

proc call*(call_606491: Call_PutAppLaunchConfiguration_606478; body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_606492 = newJObject()
  if body != nil:
    body_606492 = body
  result = call_606491.call(nil, nil, nil, nil, body_606492)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_606478(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_606479, base: "/",
    url: url_PutAppLaunchConfiguration_606480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_606493 = ref object of OpenApiRestCall_605573
proc url_PutAppReplicationConfiguration_606495(protocol: Scheme; host: string;
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

proc validate_PutAppReplicationConfiguration_606494(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606496 = header.getOrDefault("X-Amz-Target")
  valid_606496 = validateParameter(valid_606496, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_606496 != nil:
    section.add "X-Amz-Target", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Signature")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Signature", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Content-Sha256", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Date")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Date", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Credential")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Credential", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Security-Token")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Security-Token", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Algorithm")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Algorithm", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-SignedHeaders", valid_606503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606505: Call_PutAppReplicationConfiguration_606493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a replication configuration for an application.
  ## 
  let valid = call_606505.validator(path, query, header, formData, body)
  let scheme = call_606505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606505.url(scheme.get, call_606505.host, call_606505.base,
                         call_606505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606505, url, valid)

proc call*(call_606506: Call_PutAppReplicationConfiguration_606493; body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject (required)
  var body_606507 = newJObject()
  if body != nil:
    body_606507 = body
  result = call_606506.call(nil, nil, nil, nil, body_606507)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_606493(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_606494, base: "/",
    url: url_PutAppReplicationConfiguration_606495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_606508 = ref object of OpenApiRestCall_605573
proc url_StartAppReplication_606510(protocol: Scheme; host: string; base: string;
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

proc validate_StartAppReplication_606509(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606511 = header.getOrDefault("X-Amz-Target")
  valid_606511 = validateParameter(valid_606511, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_606511 != nil:
    section.add "X-Amz-Target", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Signature")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Signature", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Content-Sha256", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Date")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Date", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Credential")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Credential", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Security-Token")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Security-Token", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Algorithm")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Algorithm", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-SignedHeaders", valid_606518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606520: Call_StartAppReplication_606508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts replicating an application.
  ## 
  let valid = call_606520.validator(path, query, header, formData, body)
  let scheme = call_606520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606520.url(scheme.get, call_606520.host, call_606520.base,
                         call_606520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606520, url, valid)

proc call*(call_606521: Call_StartAppReplication_606508; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_606522 = newJObject()
  if body != nil:
    body_606522 = body
  result = call_606521.call(nil, nil, nil, nil, body_606522)

var startAppReplication* = Call_StartAppReplication_606508(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_606509, base: "/",
    url: url_StartAppReplication_606510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_606523 = ref object of OpenApiRestCall_605573
proc url_StartOnDemandReplicationRun_606525(protocol: Scheme; host: string;
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

proc validate_StartOnDemandReplicationRun_606524(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606526 = header.getOrDefault("X-Amz-Target")
  valid_606526 = validateParameter(valid_606526, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_606526 != nil:
    section.add "X-Amz-Target", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Signature")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Signature", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Content-Sha256", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Date")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Date", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Credential")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Credential", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Security-Token")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Security-Token", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Algorithm")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Algorithm", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-SignedHeaders", valid_606533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606535: Call_StartOnDemandReplicationRun_606523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  let valid = call_606535.validator(path, query, header, formData, body)
  let scheme = call_606535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606535.url(scheme.get, call_606535.host, call_606535.base,
                         call_606535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606535, url, valid)

proc call*(call_606536: Call_StartOnDemandReplicationRun_606523; body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_606537 = newJObject()
  if body != nil:
    body_606537 = body
  result = call_606536.call(nil, nil, nil, nil, body_606537)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_606523(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_606524, base: "/",
    url: url_StartOnDemandReplicationRun_606525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_606538 = ref object of OpenApiRestCall_605573
proc url_StopAppReplication_606540(protocol: Scheme; host: string; base: string;
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

proc validate_StopAppReplication_606539(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606541 = header.getOrDefault("X-Amz-Target")
  valid_606541 = validateParameter(valid_606541, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_606541 != nil:
    section.add "X-Amz-Target", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Signature")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Signature", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Content-Sha256", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Date")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Date", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Credential")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Credential", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Security-Token")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Security-Token", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Algorithm")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Algorithm", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-SignedHeaders", valid_606548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606550: Call_StopAppReplication_606538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops replicating an application.
  ## 
  let valid = call_606550.validator(path, query, header, formData, body)
  let scheme = call_606550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606550.url(scheme.get, call_606550.host, call_606550.base,
                         call_606550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606550, url, valid)

proc call*(call_606551: Call_StopAppReplication_606538; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_606552 = newJObject()
  if body != nil:
    body_606552 = body
  result = call_606551.call(nil, nil, nil, nil, body_606552)

var stopAppReplication* = Call_StopAppReplication_606538(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_606539, base: "/",
    url: url_StopAppReplication_606540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_606553 = ref object of OpenApiRestCall_605573
proc url_TerminateApp_606555(protocol: Scheme; host: string; base: string;
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

proc validate_TerminateApp_606554(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606556 = header.getOrDefault("X-Amz-Target")
  valid_606556 = validateParameter(valid_606556, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_606556 != nil:
    section.add "X-Amz-Target", valid_606556
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606565: Call_TerminateApp_606553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the stack for an application.
  ## 
  let valid = call_606565.validator(path, query, header, formData, body)
  let scheme = call_606565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606565.url(scheme.get, call_606565.host, call_606565.base,
                         call_606565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606565, url, valid)

proc call*(call_606566: Call_TerminateApp_606553; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_606567 = newJObject()
  if body != nil:
    body_606567 = body
  result = call_606566.call(nil, nil, nil, nil, body_606567)

var terminateApp* = Call_TerminateApp_606553(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_606554, base: "/", url: url_TerminateApp_606555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_606568 = ref object of OpenApiRestCall_605573
proc url_UpdateApp_606570(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateApp_606569(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606571 = header.getOrDefault("X-Amz-Target")
  valid_606571 = validateParameter(valid_606571, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_606571 != nil:
    section.add "X-Amz-Target", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Signature")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Signature", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Content-Sha256", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Date")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Date", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Credential")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Credential", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Security-Token")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Security-Token", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Algorithm")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Algorithm", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-SignedHeaders", valid_606578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606580: Call_UpdateApp_606568; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_606580.validator(path, query, header, formData, body)
  let scheme = call_606580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606580.url(scheme.get, call_606580.host, call_606580.base,
                         call_606580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606580, url, valid)

proc call*(call_606581: Call_UpdateApp_606568; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_606582 = newJObject()
  if body != nil:
    body_606582 = body
  result = call_606581.call(nil, nil, nil, nil, body_606582)

var updateApp* = Call_UpdateApp_606568(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
                                    validator: validate_UpdateApp_606569,
                                    base: "/", url: url_UpdateApp_606570,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_606583 = ref object of OpenApiRestCall_605573
proc url_UpdateReplicationJob_606585(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateReplicationJob_606584(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606586 = header.getOrDefault("X-Amz-Target")
  valid_606586 = validateParameter(valid_606586, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_606586 != nil:
    section.add "X-Amz-Target", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Signature")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Signature", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Content-Sha256", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Date")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Date", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Credential")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Credential", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Security-Token")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Security-Token", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Algorithm")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Algorithm", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-SignedHeaders", valid_606593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606595: Call_UpdateReplicationJob_606583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified settings for the specified replication job.
  ## 
  let valid = call_606595.validator(path, query, header, formData, body)
  let scheme = call_606595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606595.url(scheme.get, call_606595.host, call_606595.base,
                         call_606595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606595, url, valid)

proc call*(call_606596: Call_UpdateReplicationJob_606583; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_606597 = newJObject()
  if body != nil:
    body_606597 = body
  result = call_606596.call(nil, nil, nil, nil, body_606597)

var updateReplicationJob* = Call_UpdateReplicationJob_606583(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_606584, base: "/",
    url: url_UpdateReplicationJob_606585, schemes: {Scheme.Https, Scheme.Http})
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
