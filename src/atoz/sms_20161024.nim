
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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
  Call_CreateApp_599689 = ref object of OpenApiRestCall_599352
proc url_CreateApp_599691(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_599690(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599803 = header.getOrDefault("X-Amz-Date")
  valid_599803 = validateParameter(valid_599803, JString, required = false,
                                 default = nil)
  if valid_599803 != nil:
    section.add "X-Amz-Date", valid_599803
  var valid_599804 = header.getOrDefault("X-Amz-Security-Token")
  valid_599804 = validateParameter(valid_599804, JString, required = false,
                                 default = nil)
  if valid_599804 != nil:
    section.add "X-Amz-Security-Token", valid_599804
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599818 = header.getOrDefault("X-Amz-Target")
  valid_599818 = validateParameter(valid_599818, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_599818 != nil:
    section.add "X-Amz-Target", valid_599818
  var valid_599819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Content-Sha256", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Algorithm")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Algorithm", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Signature")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Signature", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-SignedHeaders", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Credential")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Credential", valid_599823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599847: Call_CreateApp_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  let valid = call_599847.validator(path, query, header, formData, body)
  let scheme = call_599847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599847.url(scheme.get, call_599847.host, call_599847.base,
                         call_599847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599847, url, valid)

proc call*(call_599918: Call_CreateApp_599689; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   body: JObject (required)
  var body_599919 = newJObject()
  if body != nil:
    body_599919 = body
  result = call_599918.call(nil, nil, nil, nil, body_599919)

var createApp* = Call_CreateApp_599689(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
                                    validator: validate_CreateApp_599690,
                                    base: "/", url: url_CreateApp_599691,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_599958 = ref object of OpenApiRestCall_599352
proc url_CreateReplicationJob_599960(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReplicationJob_599959(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599961 = header.getOrDefault("X-Amz-Date")
  valid_599961 = validateParameter(valid_599961, JString, required = false,
                                 default = nil)
  if valid_599961 != nil:
    section.add "X-Amz-Date", valid_599961
  var valid_599962 = header.getOrDefault("X-Amz-Security-Token")
  valid_599962 = validateParameter(valid_599962, JString, required = false,
                                 default = nil)
  if valid_599962 != nil:
    section.add "X-Amz-Security-Token", valid_599962
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599963 = header.getOrDefault("X-Amz-Target")
  valid_599963 = validateParameter(valid_599963, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_599963 != nil:
    section.add "X-Amz-Target", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Content-Sha256", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Algorithm")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Algorithm", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Signature")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Signature", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-SignedHeaders", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Credential")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Credential", valid_599968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599970: Call_CreateReplicationJob_599958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  let valid = call_599970.validator(path, query, header, formData, body)
  let scheme = call_599970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599970.url(scheme.get, call_599970.host, call_599970.base,
                         call_599970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599970, url, valid)

proc call*(call_599971: Call_CreateReplicationJob_599958; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   body: JObject (required)
  var body_599972 = newJObject()
  if body != nil:
    body_599972 = body
  result = call_599971.call(nil, nil, nil, nil, body_599972)

var createReplicationJob* = Call_CreateReplicationJob_599958(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_599959, base: "/",
    url: url_CreateReplicationJob_599960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_599973 = ref object of OpenApiRestCall_599352
proc url_DeleteApp_599975(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_599974(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599976 = header.getOrDefault("X-Amz-Date")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Date", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Security-Token")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Security-Token", valid_599977
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599978 = header.getOrDefault("X-Amz-Target")
  valid_599978 = validateParameter(valid_599978, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_599978 != nil:
    section.add "X-Amz-Target", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Content-Sha256", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Algorithm")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Algorithm", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Signature")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Signature", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-SignedHeaders", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Credential")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Credential", valid_599983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599985: Call_DeleteApp_599973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  let valid = call_599985.validator(path, query, header, formData, body)
  let scheme = call_599985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599985.url(scheme.get, call_599985.host, call_599985.base,
                         call_599985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599985, url, valid)

proc call*(call_599986: Call_DeleteApp_599973; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   body: JObject (required)
  var body_599987 = newJObject()
  if body != nil:
    body_599987 = body
  result = call_599986.call(nil, nil, nil, nil, body_599987)

var deleteApp* = Call_DeleteApp_599973(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
                                    validator: validate_DeleteApp_599974,
                                    base: "/", url: url_DeleteApp_599975,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_599988 = ref object of OpenApiRestCall_599352
proc url_DeleteAppLaunchConfiguration_599990(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppLaunchConfiguration_599989(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599991 = header.getOrDefault("X-Amz-Date")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Date", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Security-Token")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Security-Token", valid_599992
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599993 = header.getOrDefault("X-Amz-Target")
  valid_599993 = validateParameter(valid_599993, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_599993 != nil:
    section.add "X-Amz-Target", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-Content-Sha256", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Algorithm")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Algorithm", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Signature")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Signature", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-SignedHeaders", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Credential")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Credential", valid_599998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600000: Call_DeleteAppLaunchConfiguration_599988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes existing launch configuration for an application.
  ## 
  let valid = call_600000.validator(path, query, header, formData, body)
  let scheme = call_600000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600000.url(scheme.get, call_600000.host, call_600000.base,
                         call_600000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600000, url, valid)

proc call*(call_600001: Call_DeleteAppLaunchConfiguration_599988; body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_600002 = newJObject()
  if body != nil:
    body_600002 = body
  result = call_600001.call(nil, nil, nil, nil, body_600002)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_599988(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_599989, base: "/",
    url: url_DeleteAppLaunchConfiguration_599990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_600003 = ref object of OpenApiRestCall_599352
proc url_DeleteAppReplicationConfiguration_600005(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppReplicationConfiguration_600004(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600006 = header.getOrDefault("X-Amz-Date")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Date", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Security-Token")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Security-Token", valid_600007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600008 = header.getOrDefault("X-Amz-Target")
  valid_600008 = validateParameter(valid_600008, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_600008 != nil:
    section.add "X-Amz-Target", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Content-Sha256", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Algorithm")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Algorithm", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Signature")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Signature", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-SignedHeaders", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Credential")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Credential", valid_600013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600015: Call_DeleteAppReplicationConfiguration_600003;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes existing replication configuration for an application.
  ## 
  let valid = call_600015.validator(path, query, header, formData, body)
  let scheme = call_600015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600015.url(scheme.get, call_600015.host, call_600015.base,
                         call_600015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600015, url, valid)

proc call*(call_600016: Call_DeleteAppReplicationConfiguration_600003;
          body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_600017 = newJObject()
  if body != nil:
    body_600017 = body
  result = call_600016.call(nil, nil, nil, nil, body_600017)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_600003(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_600004, base: "/",
    url: url_DeleteAppReplicationConfiguration_600005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_600018 = ref object of OpenApiRestCall_599352
proc url_DeleteReplicationJob_600020(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReplicationJob_600019(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600021 = header.getOrDefault("X-Amz-Date")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Date", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Security-Token")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Security-Token", valid_600022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600023 = header.getOrDefault("X-Amz-Target")
  valid_600023 = validateParameter(valid_600023, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_600023 != nil:
    section.add "X-Amz-Target", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Content-Sha256", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Algorithm")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Algorithm", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Signature")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Signature", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-SignedHeaders", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Credential")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Credential", valid_600028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600030: Call_DeleteReplicationJob_600018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  let valid = call_600030.validator(path, query, header, formData, body)
  let scheme = call_600030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600030.url(scheme.get, call_600030.host, call_600030.base,
                         call_600030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600030, url, valid)

proc call*(call_600031: Call_DeleteReplicationJob_600018; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   body: JObject (required)
  var body_600032 = newJObject()
  if body != nil:
    body_600032 = body
  result = call_600031.call(nil, nil, nil, nil, body_600032)

var deleteReplicationJob* = Call_DeleteReplicationJob_600018(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_600019, base: "/",
    url: url_DeleteReplicationJob_600020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_600033 = ref object of OpenApiRestCall_599352
proc url_DeleteServerCatalog_600035(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServerCatalog_600034(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600036 = header.getOrDefault("X-Amz-Date")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Date", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Security-Token")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Security-Token", valid_600037
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600038 = header.getOrDefault("X-Amz-Target")
  valid_600038 = validateParameter(valid_600038, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_600038 != nil:
    section.add "X-Amz-Target", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Content-Sha256", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Algorithm")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Algorithm", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Signature")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Signature", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-SignedHeaders", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Credential")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Credential", valid_600043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600045: Call_DeleteServerCatalog_600033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all servers from your server catalog.
  ## 
  let valid = call_600045.validator(path, query, header, formData, body)
  let scheme = call_600045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600045.url(scheme.get, call_600045.host, call_600045.base,
                         call_600045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600045, url, valid)

proc call*(call_600046: Call_DeleteServerCatalog_600033; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_600047 = newJObject()
  if body != nil:
    body_600047 = body
  result = call_600046.call(nil, nil, nil, nil, body_600047)

var deleteServerCatalog* = Call_DeleteServerCatalog_600033(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_600034, base: "/",
    url: url_DeleteServerCatalog_600035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_600048 = ref object of OpenApiRestCall_599352
proc url_DisassociateConnector_600050(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConnector_600049(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600051 = header.getOrDefault("X-Amz-Date")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Date", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Security-Token")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Security-Token", valid_600052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600053 = header.getOrDefault("X-Amz-Target")
  valid_600053 = validateParameter(valid_600053, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_600053 != nil:
    section.add "X-Amz-Target", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Content-Sha256", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Algorithm")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Algorithm", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Signature")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Signature", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-SignedHeaders", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Credential")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Credential", valid_600058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600060: Call_DisassociateConnector_600048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  let valid = call_600060.validator(path, query, header, formData, body)
  let scheme = call_600060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600060.url(scheme.get, call_600060.host, call_600060.base,
                         call_600060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600060, url, valid)

proc call*(call_600061: Call_DisassociateConnector_600048; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   body: JObject (required)
  var body_600062 = newJObject()
  if body != nil:
    body_600062 = body
  result = call_600061.call(nil, nil, nil, nil, body_600062)

var disassociateConnector* = Call_DisassociateConnector_600048(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_600049, base: "/",
    url: url_DisassociateConnector_600050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_600063 = ref object of OpenApiRestCall_599352
proc url_GenerateChangeSet_600065(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateChangeSet_600064(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600066 = header.getOrDefault("X-Amz-Date")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Date", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Security-Token")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Security-Token", valid_600067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600068 = header.getOrDefault("X-Amz-Target")
  valid_600068 = validateParameter(valid_600068, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_600068 != nil:
    section.add "X-Amz-Target", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Content-Sha256", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Algorithm")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Algorithm", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Signature")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Signature", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-SignedHeaders", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Credential")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Credential", valid_600073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600075: Call_GenerateChangeSet_600063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_600075.validator(path, query, header, formData, body)
  let scheme = call_600075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600075.url(scheme.get, call_600075.host, call_600075.base,
                         call_600075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600075, url, valid)

proc call*(call_600076: Call_GenerateChangeSet_600063; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_600077 = newJObject()
  if body != nil:
    body_600077 = body
  result = call_600076.call(nil, nil, nil, nil, body_600077)

var generateChangeSet* = Call_GenerateChangeSet_600063(name: "generateChangeSet",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_600064, base: "/",
    url: url_GenerateChangeSet_600065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_600078 = ref object of OpenApiRestCall_599352
proc url_GenerateTemplate_600080(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateTemplate_600079(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600081 = header.getOrDefault("X-Amz-Date")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Date", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Security-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Security-Token", valid_600082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600083 = header.getOrDefault("X-Amz-Target")
  valid_600083 = validateParameter(valid_600083, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_600083 != nil:
    section.add "X-Amz-Target", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Content-Sha256", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Algorithm")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Algorithm", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Signature")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Signature", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-SignedHeaders", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Credential")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Credential", valid_600088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600090: Call_GenerateTemplate_600078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_600090.validator(path, query, header, formData, body)
  let scheme = call_600090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600090.url(scheme.get, call_600090.host, call_600090.base,
                         call_600090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600090, url, valid)

proc call*(call_600091: Call_GenerateTemplate_600078; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_600092 = newJObject()
  if body != nil:
    body_600092 = body
  result = call_600091.call(nil, nil, nil, nil, body_600092)

var generateTemplate* = Call_GenerateTemplate_600078(name: "generateTemplate",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_600079, base: "/",
    url: url_GenerateTemplate_600080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_600093 = ref object of OpenApiRestCall_599352
proc url_GetApp_600095(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApp_600094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600096 = header.getOrDefault("X-Amz-Date")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Date", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Security-Token")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Security-Token", valid_600097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600098 = header.getOrDefault("X-Amz-Target")
  valid_600098 = validateParameter(valid_600098, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_600098 != nil:
    section.add "X-Amz-Target", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Content-Sha256", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Algorithm")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Algorithm", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Signature")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Signature", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-SignedHeaders", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Credential")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Credential", valid_600103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600105: Call_GetApp_600093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_600105.validator(path, query, header, formData, body)
  let scheme = call_600105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600105.url(scheme.get, call_600105.host, call_600105.base,
                         call_600105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600105, url, valid)

proc call*(call_600106: Call_GetApp_600093; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_600107 = newJObject()
  if body != nil:
    body_600107 = body
  result = call_600106.call(nil, nil, nil, nil, body_600107)

var getApp* = Call_GetApp_600093(name: "getApp", meth: HttpMethod.HttpPost,
                              host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                              validator: validate_GetApp_600094, base: "/",
                              url: url_GetApp_600095,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_600108 = ref object of OpenApiRestCall_599352
proc url_GetAppLaunchConfiguration_600110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppLaunchConfiguration_600109(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600111 = header.getOrDefault("X-Amz-Date")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Date", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Security-Token")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Security-Token", valid_600112
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600113 = header.getOrDefault("X-Amz-Target")
  valid_600113 = validateParameter(valid_600113, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_600113 != nil:
    section.add "X-Amz-Target", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Content-Sha256", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Algorithm")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Algorithm", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Signature")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Signature", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-SignedHeaders", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Credential")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Credential", valid_600118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600120: Call_GetAppLaunchConfiguration_600108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  let valid = call_600120.validator(path, query, header, formData, body)
  let scheme = call_600120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600120.url(scheme.get, call_600120.host, call_600120.base,
                         call_600120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600120, url, valid)

proc call*(call_600121: Call_GetAppLaunchConfiguration_600108; body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   body: JObject (required)
  var body_600122 = newJObject()
  if body != nil:
    body_600122 = body
  result = call_600121.call(nil, nil, nil, nil, body_600122)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_600108(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_600109, base: "/",
    url: url_GetAppLaunchConfiguration_600110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_600123 = ref object of OpenApiRestCall_599352
proc url_GetAppReplicationConfiguration_600125(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppReplicationConfiguration_600124(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600126 = header.getOrDefault("X-Amz-Date")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Date", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Security-Token")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Security-Token", valid_600127
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600128 = header.getOrDefault("X-Amz-Target")
  valid_600128 = validateParameter(valid_600128, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_600128 != nil:
    section.add "X-Amz-Target", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Content-Sha256", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Algorithm")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Algorithm", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Signature")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Signature", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-SignedHeaders", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Credential")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Credential", valid_600133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600135: Call_GetAppReplicationConfiguration_600123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  let valid = call_600135.validator(path, query, header, formData, body)
  let scheme = call_600135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600135.url(scheme.get, call_600135.host, call_600135.base,
                         call_600135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600135, url, valid)

proc call*(call_600136: Call_GetAppReplicationConfiguration_600123; body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   body: JObject (required)
  var body_600137 = newJObject()
  if body != nil:
    body_600137 = body
  result = call_600136.call(nil, nil, nil, nil, body_600137)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_600123(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_600124, base: "/",
    url: url_GetAppReplicationConfiguration_600125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_600138 = ref object of OpenApiRestCall_599352
proc url_GetConnectors_600140(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnectors_600139(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600141 = query.getOrDefault("maxResults")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "maxResults", valid_600141
  var valid_600142 = query.getOrDefault("nextToken")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "nextToken", valid_600142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600143 = header.getOrDefault("X-Amz-Date")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Date", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Security-Token")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Security-Token", valid_600144
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600145 = header.getOrDefault("X-Amz-Target")
  valid_600145 = validateParameter(valid_600145, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_600145 != nil:
    section.add "X-Amz-Target", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Content-Sha256", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Algorithm")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Algorithm", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Signature")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Signature", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-SignedHeaders", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Credential")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Credential", valid_600150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600152: Call_GetConnectors_600138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  let valid = call_600152.validator(path, query, header, formData, body)
  let scheme = call_600152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600152.url(scheme.get, call_600152.host, call_600152.base,
                         call_600152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600152, url, valid)

proc call*(call_600153: Call_GetConnectors_600138; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600154 = newJObject()
  var body_600155 = newJObject()
  add(query_600154, "maxResults", newJString(maxResults))
  add(query_600154, "nextToken", newJString(nextToken))
  if body != nil:
    body_600155 = body
  result = call_600153.call(nil, query_600154, nil, nil, body_600155)

var getConnectors* = Call_GetConnectors_600138(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_600139, base: "/", url: url_GetConnectors_600140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_600157 = ref object of OpenApiRestCall_599352
proc url_GetReplicationJobs_600159(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReplicationJobs_600158(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600160 = query.getOrDefault("maxResults")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "maxResults", valid_600160
  var valid_600161 = query.getOrDefault("nextToken")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "nextToken", valid_600161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600162 = header.getOrDefault("X-Amz-Date")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Date", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Security-Token")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Security-Token", valid_600163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600164 = header.getOrDefault("X-Amz-Target")
  valid_600164 = validateParameter(valid_600164, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_600164 != nil:
    section.add "X-Amz-Target", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Content-Sha256", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Algorithm")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Algorithm", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Signature")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Signature", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-SignedHeaders", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Credential")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Credential", valid_600169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600171: Call_GetReplicationJobs_600157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  let valid = call_600171.validator(path, query, header, formData, body)
  let scheme = call_600171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600171.url(scheme.get, call_600171.host, call_600171.base,
                         call_600171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600171, url, valid)

proc call*(call_600172: Call_GetReplicationJobs_600157; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600173 = newJObject()
  var body_600174 = newJObject()
  add(query_600173, "maxResults", newJString(maxResults))
  add(query_600173, "nextToken", newJString(nextToken))
  if body != nil:
    body_600174 = body
  result = call_600172.call(nil, query_600173, nil, nil, body_600174)

var getReplicationJobs* = Call_GetReplicationJobs_600157(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_600158, base: "/",
    url: url_GetReplicationJobs_600159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_600175 = ref object of OpenApiRestCall_599352
proc url_GetReplicationRuns_600177(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReplicationRuns_600176(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes the replication runs for the specified replication job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600178 = query.getOrDefault("maxResults")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "maxResults", valid_600178
  var valid_600179 = query.getOrDefault("nextToken")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "nextToken", valid_600179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600180 = header.getOrDefault("X-Amz-Date")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Date", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Security-Token")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Security-Token", valid_600181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600182 = header.getOrDefault("X-Amz-Target")
  valid_600182 = validateParameter(valid_600182, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_600182 != nil:
    section.add "X-Amz-Target", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Content-Sha256", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Algorithm")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Algorithm", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Signature")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Signature", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-SignedHeaders", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Credential")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Credential", valid_600187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600189: Call_GetReplicationRuns_600175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the replication runs for the specified replication job.
  ## 
  let valid = call_600189.validator(path, query, header, formData, body)
  let scheme = call_600189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600189.url(scheme.get, call_600189.host, call_600189.base,
                         call_600189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600189, url, valid)

proc call*(call_600190: Call_GetReplicationRuns_600175; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600191 = newJObject()
  var body_600192 = newJObject()
  add(query_600191, "maxResults", newJString(maxResults))
  add(query_600191, "nextToken", newJString(nextToken))
  if body != nil:
    body_600192 = body
  result = call_600190.call(nil, query_600191, nil, nil, body_600192)

var getReplicationRuns* = Call_GetReplicationRuns_600175(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_600176, base: "/",
    url: url_GetReplicationRuns_600177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_600193 = ref object of OpenApiRestCall_599352
proc url_GetServers_600195(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServers_600194(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600196 = query.getOrDefault("maxResults")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "maxResults", valid_600196
  var valid_600197 = query.getOrDefault("nextToken")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "nextToken", valid_600197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600198 = header.getOrDefault("X-Amz-Date")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Date", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Security-Token")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Security-Token", valid_600199
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600200 = header.getOrDefault("X-Amz-Target")
  valid_600200 = validateParameter(valid_600200, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_600200 != nil:
    section.add "X-Amz-Target", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Content-Sha256", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Algorithm")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Algorithm", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Signature")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Signature", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-SignedHeaders", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Credential")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Credential", valid_600205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600207: Call_GetServers_600193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  let valid = call_600207.validator(path, query, header, formData, body)
  let scheme = call_600207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600207.url(scheme.get, call_600207.host, call_600207.base,
                         call_600207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600207, url, valid)

proc call*(call_600208: Call_GetServers_600193; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600209 = newJObject()
  var body_600210 = newJObject()
  add(query_600209, "maxResults", newJString(maxResults))
  add(query_600209, "nextToken", newJString(nextToken))
  if body != nil:
    body_600210 = body
  result = call_600208.call(nil, query_600209, nil, nil, body_600210)

var getServers* = Call_GetServers_600193(name: "getServers",
                                      meth: HttpMethod.HttpPost,
                                      host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
                                      validator: validate_GetServers_600194,
                                      base: "/", url: url_GetServers_600195,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_600211 = ref object of OpenApiRestCall_599352
proc url_ImportServerCatalog_600213(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportServerCatalog_600212(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600214 = header.getOrDefault("X-Amz-Date")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Date", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Security-Token")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Security-Token", valid_600215
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600216 = header.getOrDefault("X-Amz-Target")
  valid_600216 = validateParameter(valid_600216, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_600216 != nil:
    section.add "X-Amz-Target", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Content-Sha256", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Algorithm")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Algorithm", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Signature")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Signature", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-SignedHeaders", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Credential")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Credential", valid_600221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600223: Call_ImportServerCatalog_600211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  let valid = call_600223.validator(path, query, header, formData, body)
  let scheme = call_600223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600223.url(scheme.get, call_600223.host, call_600223.base,
                         call_600223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600223, url, valid)

proc call*(call_600224: Call_ImportServerCatalog_600211; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   body: JObject (required)
  var body_600225 = newJObject()
  if body != nil:
    body_600225 = body
  result = call_600224.call(nil, nil, nil, nil, body_600225)

var importServerCatalog* = Call_ImportServerCatalog_600211(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_600212, base: "/",
    url: url_ImportServerCatalog_600213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_600226 = ref object of OpenApiRestCall_599352
proc url_LaunchApp_600228(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LaunchApp_600227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600229 = header.getOrDefault("X-Amz-Date")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Date", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Security-Token")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Security-Token", valid_600230
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600231 = header.getOrDefault("X-Amz-Target")
  valid_600231 = validateParameter(valid_600231, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_600231 != nil:
    section.add "X-Amz-Target", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Content-Sha256", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Algorithm")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Algorithm", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Signature")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Signature", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-SignedHeaders", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Credential")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Credential", valid_600236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600238: Call_LaunchApp_600226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an application stack.
  ## 
  let valid = call_600238.validator(path, query, header, formData, body)
  let scheme = call_600238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600238.url(scheme.get, call_600238.host, call_600238.base,
                         call_600238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600238, url, valid)

proc call*(call_600239: Call_LaunchApp_600226; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_600240 = newJObject()
  if body != nil:
    body_600240 = body
  result = call_600239.call(nil, nil, nil, nil, body_600240)

var launchApp* = Call_LaunchApp_600226(name: "launchApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
                                    validator: validate_LaunchApp_600227,
                                    base: "/", url: url_LaunchApp_600228,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_600241 = ref object of OpenApiRestCall_599352
proc url_ListApps_600243(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_600242(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600244 = header.getOrDefault("X-Amz-Date")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Date", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Security-Token")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Security-Token", valid_600245
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600246 = header.getOrDefault("X-Amz-Target")
  valid_600246 = validateParameter(valid_600246, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_600246 != nil:
    section.add "X-Amz-Target", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Content-Sha256", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Algorithm")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Algorithm", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Signature")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Signature", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-SignedHeaders", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Credential")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Credential", valid_600251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600253: Call_ListApps_600241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of summaries for all applications.
  ## 
  let valid = call_600253.validator(path, query, header, formData, body)
  let scheme = call_600253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600253.url(scheme.get, call_600253.host, call_600253.base,
                         call_600253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600253, url, valid)

proc call*(call_600254: Call_ListApps_600241; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_600255 = newJObject()
  if body != nil:
    body_600255 = body
  result = call_600254.call(nil, nil, nil, nil, body_600255)

var listApps* = Call_ListApps_600241(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                  validator: validate_ListApps_600242, base: "/",
                                  url: url_ListApps_600243,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_600256 = ref object of OpenApiRestCall_599352
proc url_PutAppLaunchConfiguration_600258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppLaunchConfiguration_600257(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600259 = header.getOrDefault("X-Amz-Date")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Date", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Security-Token")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Security-Token", valid_600260
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600261 = header.getOrDefault("X-Amz-Target")
  valid_600261 = validateParameter(valid_600261, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_600261 != nil:
    section.add "X-Amz-Target", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Content-Sha256", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Algorithm")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Algorithm", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Signature")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Signature", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-SignedHeaders", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Credential")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Credential", valid_600266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600268: Call_PutAppLaunchConfiguration_600256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a launch configuration for an application.
  ## 
  let valid = call_600268.validator(path, query, header, formData, body)
  let scheme = call_600268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600268.url(scheme.get, call_600268.host, call_600268.base,
                         call_600268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600268, url, valid)

proc call*(call_600269: Call_PutAppLaunchConfiguration_600256; body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_600270 = newJObject()
  if body != nil:
    body_600270 = body
  result = call_600269.call(nil, nil, nil, nil, body_600270)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_600256(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_600257, base: "/",
    url: url_PutAppLaunchConfiguration_600258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_600271 = ref object of OpenApiRestCall_599352
proc url_PutAppReplicationConfiguration_600273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppReplicationConfiguration_600272(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600274 = header.getOrDefault("X-Amz-Date")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Date", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Security-Token")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Security-Token", valid_600275
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600276 = header.getOrDefault("X-Amz-Target")
  valid_600276 = validateParameter(valid_600276, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_600276 != nil:
    section.add "X-Amz-Target", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Content-Sha256", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Algorithm")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Algorithm", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Signature")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Signature", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-SignedHeaders", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Credential")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Credential", valid_600281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600283: Call_PutAppReplicationConfiguration_600271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a replication configuration for an application.
  ## 
  let valid = call_600283.validator(path, query, header, formData, body)
  let scheme = call_600283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600283.url(scheme.get, call_600283.host, call_600283.base,
                         call_600283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600283, url, valid)

proc call*(call_600284: Call_PutAppReplicationConfiguration_600271; body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject (required)
  var body_600285 = newJObject()
  if body != nil:
    body_600285 = body
  result = call_600284.call(nil, nil, nil, nil, body_600285)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_600271(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_600272, base: "/",
    url: url_PutAppReplicationConfiguration_600273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_600286 = ref object of OpenApiRestCall_599352
proc url_StartAppReplication_600288(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAppReplication_600287(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600289 = header.getOrDefault("X-Amz-Date")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Date", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Security-Token")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Security-Token", valid_600290
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600291 = header.getOrDefault("X-Amz-Target")
  valid_600291 = validateParameter(valid_600291, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_600291 != nil:
    section.add "X-Amz-Target", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Content-Sha256", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Algorithm")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Algorithm", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Signature")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Signature", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-SignedHeaders", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Credential")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Credential", valid_600296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600298: Call_StartAppReplication_600286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts replicating an application.
  ## 
  let valid = call_600298.validator(path, query, header, formData, body)
  let scheme = call_600298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600298.url(scheme.get, call_600298.host, call_600298.base,
                         call_600298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600298, url, valid)

proc call*(call_600299: Call_StartAppReplication_600286; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_600300 = newJObject()
  if body != nil:
    body_600300 = body
  result = call_600299.call(nil, nil, nil, nil, body_600300)

var startAppReplication* = Call_StartAppReplication_600286(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_600287, base: "/",
    url: url_StartAppReplication_600288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_600301 = ref object of OpenApiRestCall_599352
proc url_StartOnDemandReplicationRun_600303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartOnDemandReplicationRun_600302(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600304 = header.getOrDefault("X-Amz-Date")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-Date", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Security-Token")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Security-Token", valid_600305
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600306 = header.getOrDefault("X-Amz-Target")
  valid_600306 = validateParameter(valid_600306, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_600306 != nil:
    section.add "X-Amz-Target", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Content-Sha256", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Algorithm")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Algorithm", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Signature")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Signature", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-SignedHeaders", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Credential")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Credential", valid_600311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600313: Call_StartOnDemandReplicationRun_600301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  let valid = call_600313.validator(path, query, header, formData, body)
  let scheme = call_600313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600313.url(scheme.get, call_600313.host, call_600313.base,
                         call_600313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600313, url, valid)

proc call*(call_600314: Call_StartOnDemandReplicationRun_600301; body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_600315 = newJObject()
  if body != nil:
    body_600315 = body
  result = call_600314.call(nil, nil, nil, nil, body_600315)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_600301(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_600302, base: "/",
    url: url_StartOnDemandReplicationRun_600303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_600316 = ref object of OpenApiRestCall_599352
proc url_StopAppReplication_600318(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAppReplication_600317(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600319 = header.getOrDefault("X-Amz-Date")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Date", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Security-Token")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Security-Token", valid_600320
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600321 = header.getOrDefault("X-Amz-Target")
  valid_600321 = validateParameter(valid_600321, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_600321 != nil:
    section.add "X-Amz-Target", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Content-Sha256", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Algorithm")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Algorithm", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Signature")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Signature", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-SignedHeaders", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Credential")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Credential", valid_600326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600328: Call_StopAppReplication_600316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops replicating an application.
  ## 
  let valid = call_600328.validator(path, query, header, formData, body)
  let scheme = call_600328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600328.url(scheme.get, call_600328.host, call_600328.base,
                         call_600328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600328, url, valid)

proc call*(call_600329: Call_StopAppReplication_600316; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_600330 = newJObject()
  if body != nil:
    body_600330 = body
  result = call_600329.call(nil, nil, nil, nil, body_600330)

var stopAppReplication* = Call_StopAppReplication_600316(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_600317, base: "/",
    url: url_StopAppReplication_600318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_600331 = ref object of OpenApiRestCall_599352
proc url_TerminateApp_600333(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateApp_600332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600334 = header.getOrDefault("X-Amz-Date")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Date", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Security-Token")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Security-Token", valid_600335
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600336 = header.getOrDefault("X-Amz-Target")
  valid_600336 = validateParameter(valid_600336, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_600336 != nil:
    section.add "X-Amz-Target", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Content-Sha256", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Algorithm")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Algorithm", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Signature")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Signature", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-SignedHeaders", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Credential")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Credential", valid_600341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600343: Call_TerminateApp_600331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the stack for an application.
  ## 
  let valid = call_600343.validator(path, query, header, formData, body)
  let scheme = call_600343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600343.url(scheme.get, call_600343.host, call_600343.base,
                         call_600343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600343, url, valid)

proc call*(call_600344: Call_TerminateApp_600331; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_600345 = newJObject()
  if body != nil:
    body_600345 = body
  result = call_600344.call(nil, nil, nil, nil, body_600345)

var terminateApp* = Call_TerminateApp_600331(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_600332, base: "/", url: url_TerminateApp_600333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_600346 = ref object of OpenApiRestCall_599352
proc url_UpdateApp_600348(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApp_600347(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600349 = header.getOrDefault("X-Amz-Date")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Date", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Security-Token")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Security-Token", valid_600350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600351 = header.getOrDefault("X-Amz-Target")
  valid_600351 = validateParameter(valid_600351, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_600351 != nil:
    section.add "X-Amz-Target", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Content-Sha256", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Algorithm")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Algorithm", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Signature")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Signature", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-SignedHeaders", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Credential")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Credential", valid_600356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600358: Call_UpdateApp_600346; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_600358.validator(path, query, header, formData, body)
  let scheme = call_600358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600358.url(scheme.get, call_600358.host, call_600358.base,
                         call_600358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600358, url, valid)

proc call*(call_600359: Call_UpdateApp_600346; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_600360 = newJObject()
  if body != nil:
    body_600360 = body
  result = call_600359.call(nil, nil, nil, nil, body_600360)

var updateApp* = Call_UpdateApp_600346(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
                                    validator: validate_UpdateApp_600347,
                                    base: "/", url: url_UpdateApp_600348,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_600361 = ref object of OpenApiRestCall_599352
proc url_UpdateReplicationJob_600363(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateReplicationJob_600362(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600364 = header.getOrDefault("X-Amz-Date")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-Date", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Security-Token")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Security-Token", valid_600365
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600366 = header.getOrDefault("X-Amz-Target")
  valid_600366 = validateParameter(valid_600366, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_600366 != nil:
    section.add "X-Amz-Target", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Content-Sha256", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Algorithm")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Algorithm", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Signature")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Signature", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-SignedHeaders", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Credential")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Credential", valid_600371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600373: Call_UpdateReplicationJob_600361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified settings for the specified replication job.
  ## 
  let valid = call_600373.validator(path, query, header, formData, body)
  let scheme = call_600373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600373.url(scheme.get, call_600373.host, call_600373.base,
                         call_600373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600373, url, valid)

proc call*(call_600374: Call_UpdateReplicationJob_600361; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_600375 = newJObject()
  if body != nil:
    body_600375 = body
  result = call_600374.call(nil, nil, nil, nil, body_600375)

var updateReplicationJob* = Call_UpdateReplicationJob_600361(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_600362, base: "/",
    url: url_UpdateReplicationJob_600363, schemes: {Scheme.Https, Scheme.Http})
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
