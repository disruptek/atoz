
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600410 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600410](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600410): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_600752 = ref object of OpenApiRestCall_600410
proc url_CreateApp_600754(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApp_600753(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600866 = header.getOrDefault("X-Amz-Date")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-Date", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-Security-Token")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-Security-Token", valid_600867
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600881 = header.getOrDefault("X-Amz-Target")
  valid_600881 = validateParameter(valid_600881, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_600881 != nil:
    section.add "X-Amz-Target", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Content-Sha256", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Algorithm")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Algorithm", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Signature")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Signature", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-SignedHeaders", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Credential")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Credential", valid_600886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600910: Call_CreateApp_600752; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  let valid = call_600910.validator(path, query, header, formData, body)
  let scheme = call_600910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600910.url(scheme.get, call_600910.host, call_600910.base,
                         call_600910.route, valid.getOrDefault("path"))
  result = hook(call_600910, url, valid)

proc call*(call_600981: Call_CreateApp_600752; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   body: JObject (required)
  var body_600982 = newJObject()
  if body != nil:
    body_600982 = body
  result = call_600981.call(nil, nil, nil, nil, body_600982)

var createApp* = Call_CreateApp_600752(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
                                    validator: validate_CreateApp_600753,
                                    base: "/", url: url_CreateApp_600754,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_601021 = ref object of OpenApiRestCall_600410
proc url_CreateReplicationJob_601023(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationJob_601022(path: JsonNode; query: JsonNode;
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
  var valid_601024 = header.getOrDefault("X-Amz-Date")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Date", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-Security-Token")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Security-Token", valid_601025
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601026 = header.getOrDefault("X-Amz-Target")
  valid_601026 = validateParameter(valid_601026, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_601026 != nil:
    section.add "X-Amz-Target", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Content-Sha256", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Algorithm")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Algorithm", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Signature")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Signature", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-SignedHeaders", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Credential")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Credential", valid_601031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601033: Call_CreateReplicationJob_601021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  let valid = call_601033.validator(path, query, header, formData, body)
  let scheme = call_601033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601033.url(scheme.get, call_601033.host, call_601033.base,
                         call_601033.route, valid.getOrDefault("path"))
  result = hook(call_601033, url, valid)

proc call*(call_601034: Call_CreateReplicationJob_601021; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   body: JObject (required)
  var body_601035 = newJObject()
  if body != nil:
    body_601035 = body
  result = call_601034.call(nil, nil, nil, nil, body_601035)

var createReplicationJob* = Call_CreateReplicationJob_601021(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_601022, base: "/",
    url: url_CreateReplicationJob_601023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_601036 = ref object of OpenApiRestCall_600410
proc url_DeleteApp_601038(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteApp_601037(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601039 = header.getOrDefault("X-Amz-Date")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Date", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Security-Token")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Security-Token", valid_601040
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601041 = header.getOrDefault("X-Amz-Target")
  valid_601041 = validateParameter(valid_601041, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_601041 != nil:
    section.add "X-Amz-Target", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601048: Call_DeleteApp_601036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  let valid = call_601048.validator(path, query, header, formData, body)
  let scheme = call_601048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601048.url(scheme.get, call_601048.host, call_601048.base,
                         call_601048.route, valid.getOrDefault("path"))
  result = hook(call_601048, url, valid)

proc call*(call_601049: Call_DeleteApp_601036; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   body: JObject (required)
  var body_601050 = newJObject()
  if body != nil:
    body_601050 = body
  result = call_601049.call(nil, nil, nil, nil, body_601050)

var deleteApp* = Call_DeleteApp_601036(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
                                    validator: validate_DeleteApp_601037,
                                    base: "/", url: url_DeleteApp_601038,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_601051 = ref object of OpenApiRestCall_600410
proc url_DeleteAppLaunchConfiguration_601053(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAppLaunchConfiguration_601052(path: JsonNode; query: JsonNode;
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
  var valid_601054 = header.getOrDefault("X-Amz-Date")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Date", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Security-Token")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Security-Token", valid_601055
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601056 = header.getOrDefault("X-Amz-Target")
  valid_601056 = validateParameter(valid_601056, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_601056 != nil:
    section.add "X-Amz-Target", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Content-Sha256", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Algorithm")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Algorithm", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Signature")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Signature", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-SignedHeaders", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Credential")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Credential", valid_601061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601063: Call_DeleteAppLaunchConfiguration_601051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes existing launch configuration for an application.
  ## 
  let valid = call_601063.validator(path, query, header, formData, body)
  let scheme = call_601063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601063.url(scheme.get, call_601063.host, call_601063.base,
                         call_601063.route, valid.getOrDefault("path"))
  result = hook(call_601063, url, valid)

proc call*(call_601064: Call_DeleteAppLaunchConfiguration_601051; body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_601065 = newJObject()
  if body != nil:
    body_601065 = body
  result = call_601064.call(nil, nil, nil, nil, body_601065)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_601051(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_601052, base: "/",
    url: url_DeleteAppLaunchConfiguration_601053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_601066 = ref object of OpenApiRestCall_600410
proc url_DeleteAppReplicationConfiguration_601068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAppReplicationConfiguration_601067(path: JsonNode;
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
  var valid_601069 = header.getOrDefault("X-Amz-Date")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Date", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Security-Token")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Security-Token", valid_601070
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601071 = header.getOrDefault("X-Amz-Target")
  valid_601071 = validateParameter(valid_601071, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_601071 != nil:
    section.add "X-Amz-Target", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Content-Sha256", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Algorithm")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Algorithm", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Signature")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Signature", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-SignedHeaders", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Credential")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Credential", valid_601076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601078: Call_DeleteAppReplicationConfiguration_601066;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes existing replication configuration for an application.
  ## 
  let valid = call_601078.validator(path, query, header, formData, body)
  let scheme = call_601078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601078.url(scheme.get, call_601078.host, call_601078.base,
                         call_601078.route, valid.getOrDefault("path"))
  result = hook(call_601078, url, valid)

proc call*(call_601079: Call_DeleteAppReplicationConfiguration_601066;
          body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_601080 = newJObject()
  if body != nil:
    body_601080 = body
  result = call_601079.call(nil, nil, nil, nil, body_601080)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_601066(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_601067, base: "/",
    url: url_DeleteAppReplicationConfiguration_601068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_601081 = ref object of OpenApiRestCall_600410
proc url_DeleteReplicationJob_601083(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationJob_601082(path: JsonNode; query: JsonNode;
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
  var valid_601084 = header.getOrDefault("X-Amz-Date")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Date", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Security-Token")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Security-Token", valid_601085
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601086 = header.getOrDefault("X-Amz-Target")
  valid_601086 = validateParameter(valid_601086, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_601086 != nil:
    section.add "X-Amz-Target", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Content-Sha256", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Algorithm")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Algorithm", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Signature")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Signature", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-SignedHeaders", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Credential")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Credential", valid_601091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601093: Call_DeleteReplicationJob_601081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  let valid = call_601093.validator(path, query, header, formData, body)
  let scheme = call_601093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601093.url(scheme.get, call_601093.host, call_601093.base,
                         call_601093.route, valid.getOrDefault("path"))
  result = hook(call_601093, url, valid)

proc call*(call_601094: Call_DeleteReplicationJob_601081; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   body: JObject (required)
  var body_601095 = newJObject()
  if body != nil:
    body_601095 = body
  result = call_601094.call(nil, nil, nil, nil, body_601095)

var deleteReplicationJob* = Call_DeleteReplicationJob_601081(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_601082, base: "/",
    url: url_DeleteReplicationJob_601083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_601096 = ref object of OpenApiRestCall_600410
proc url_DeleteServerCatalog_601098(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteServerCatalog_601097(path: JsonNode; query: JsonNode;
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
  var valid_601099 = header.getOrDefault("X-Amz-Date")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Date", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Security-Token")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Security-Token", valid_601100
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601101 = header.getOrDefault("X-Amz-Target")
  valid_601101 = validateParameter(valid_601101, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_601101 != nil:
    section.add "X-Amz-Target", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Content-Sha256", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Algorithm")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Algorithm", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Signature")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Signature", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-SignedHeaders", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Credential")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Credential", valid_601106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601108: Call_DeleteServerCatalog_601096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all servers from your server catalog.
  ## 
  let valid = call_601108.validator(path, query, header, formData, body)
  let scheme = call_601108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601108.url(scheme.get, call_601108.host, call_601108.base,
                         call_601108.route, valid.getOrDefault("path"))
  result = hook(call_601108, url, valid)

proc call*(call_601109: Call_DeleteServerCatalog_601096; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_601110 = newJObject()
  if body != nil:
    body_601110 = body
  result = call_601109.call(nil, nil, nil, nil, body_601110)

var deleteServerCatalog* = Call_DeleteServerCatalog_601096(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_601097, base: "/",
    url: url_DeleteServerCatalog_601098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_601111 = ref object of OpenApiRestCall_600410
proc url_DisassociateConnector_601113(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateConnector_601112(path: JsonNode; query: JsonNode;
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
  var valid_601114 = header.getOrDefault("X-Amz-Date")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Date", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Security-Token")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Security-Token", valid_601115
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601116 = header.getOrDefault("X-Amz-Target")
  valid_601116 = validateParameter(valid_601116, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_601116 != nil:
    section.add "X-Amz-Target", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Content-Sha256", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Algorithm")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Algorithm", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Signature")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Signature", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-SignedHeaders", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Credential")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Credential", valid_601121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601123: Call_DisassociateConnector_601111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  let valid = call_601123.validator(path, query, header, formData, body)
  let scheme = call_601123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601123.url(scheme.get, call_601123.host, call_601123.base,
                         call_601123.route, valid.getOrDefault("path"))
  result = hook(call_601123, url, valid)

proc call*(call_601124: Call_DisassociateConnector_601111; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   body: JObject (required)
  var body_601125 = newJObject()
  if body != nil:
    body_601125 = body
  result = call_601124.call(nil, nil, nil, nil, body_601125)

var disassociateConnector* = Call_DisassociateConnector_601111(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_601112, base: "/",
    url: url_DisassociateConnector_601113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_601126 = ref object of OpenApiRestCall_600410
proc url_GenerateChangeSet_601128(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateChangeSet_601127(path: JsonNode; query: JsonNode;
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
  var valid_601129 = header.getOrDefault("X-Amz-Date")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Date", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Security-Token")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Security-Token", valid_601130
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601131 = header.getOrDefault("X-Amz-Target")
  valid_601131 = validateParameter(valid_601131, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_601131 != nil:
    section.add "X-Amz-Target", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Content-Sha256", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Algorithm")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Algorithm", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Signature")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Signature", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-SignedHeaders", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Credential")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Credential", valid_601136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601138: Call_GenerateChangeSet_601126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_601138.validator(path, query, header, formData, body)
  let scheme = call_601138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601138.url(scheme.get, call_601138.host, call_601138.base,
                         call_601138.route, valid.getOrDefault("path"))
  result = hook(call_601138, url, valid)

proc call*(call_601139: Call_GenerateChangeSet_601126; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_601140 = newJObject()
  if body != nil:
    body_601140 = body
  result = call_601139.call(nil, nil, nil, nil, body_601140)

var generateChangeSet* = Call_GenerateChangeSet_601126(name: "generateChangeSet",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_601127, base: "/",
    url: url_GenerateChangeSet_601128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_601141 = ref object of OpenApiRestCall_600410
proc url_GenerateTemplate_601143(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateTemplate_601142(path: JsonNode; query: JsonNode;
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
  var valid_601144 = header.getOrDefault("X-Amz-Date")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Date", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Security-Token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Security-Token", valid_601145
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601146 = header.getOrDefault("X-Amz-Target")
  valid_601146 = validateParameter(valid_601146, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_601146 != nil:
    section.add "X-Amz-Target", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Content-Sha256", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Algorithm")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Algorithm", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Signature")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Signature", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-SignedHeaders", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Credential")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Credential", valid_601151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601153: Call_GenerateTemplate_601141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_601153.validator(path, query, header, formData, body)
  let scheme = call_601153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601153.url(scheme.get, call_601153.host, call_601153.base,
                         call_601153.route, valid.getOrDefault("path"))
  result = hook(call_601153, url, valid)

proc call*(call_601154: Call_GenerateTemplate_601141; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_601155 = newJObject()
  if body != nil:
    body_601155 = body
  result = call_601154.call(nil, nil, nil, nil, body_601155)

var generateTemplate* = Call_GenerateTemplate_601141(name: "generateTemplate",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_601142, base: "/",
    url: url_GenerateTemplate_601143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_601156 = ref object of OpenApiRestCall_600410
proc url_GetApp_601158(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApp_601157(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601159 = header.getOrDefault("X-Amz-Date")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Date", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Security-Token")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Security-Token", valid_601160
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601161 = header.getOrDefault("X-Amz-Target")
  valid_601161 = validateParameter(valid_601161, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_601161 != nil:
    section.add "X-Amz-Target", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Content-Sha256", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Algorithm")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Algorithm", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Signature")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Signature", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-SignedHeaders", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Credential")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Credential", valid_601166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601168: Call_GetApp_601156; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_601168.validator(path, query, header, formData, body)
  let scheme = call_601168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601168.url(scheme.get, call_601168.host, call_601168.base,
                         call_601168.route, valid.getOrDefault("path"))
  result = hook(call_601168, url, valid)

proc call*(call_601169: Call_GetApp_601156; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_601170 = newJObject()
  if body != nil:
    body_601170 = body
  result = call_601169.call(nil, nil, nil, nil, body_601170)

var getApp* = Call_GetApp_601156(name: "getApp", meth: HttpMethod.HttpPost,
                              host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                              validator: validate_GetApp_601157, base: "/",
                              url: url_GetApp_601158,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_601171 = ref object of OpenApiRestCall_600410
proc url_GetAppLaunchConfiguration_601173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAppLaunchConfiguration_601172(path: JsonNode; query: JsonNode;
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
  var valid_601174 = header.getOrDefault("X-Amz-Date")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Date", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Security-Token")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Security-Token", valid_601175
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601176 = header.getOrDefault("X-Amz-Target")
  valid_601176 = validateParameter(valid_601176, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_601176 != nil:
    section.add "X-Amz-Target", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Content-Sha256", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Algorithm")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Algorithm", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Signature")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Signature", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-SignedHeaders", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Credential")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Credential", valid_601181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601183: Call_GetAppLaunchConfiguration_601171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  let valid = call_601183.validator(path, query, header, formData, body)
  let scheme = call_601183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601183.url(scheme.get, call_601183.host, call_601183.base,
                         call_601183.route, valid.getOrDefault("path"))
  result = hook(call_601183, url, valid)

proc call*(call_601184: Call_GetAppLaunchConfiguration_601171; body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   body: JObject (required)
  var body_601185 = newJObject()
  if body != nil:
    body_601185 = body
  result = call_601184.call(nil, nil, nil, nil, body_601185)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_601171(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_601172, base: "/",
    url: url_GetAppLaunchConfiguration_601173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_601186 = ref object of OpenApiRestCall_600410
proc url_GetAppReplicationConfiguration_601188(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAppReplicationConfiguration_601187(path: JsonNode;
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
  var valid_601189 = header.getOrDefault("X-Amz-Date")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Date", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Security-Token")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Security-Token", valid_601190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601191 = header.getOrDefault("X-Amz-Target")
  valid_601191 = validateParameter(valid_601191, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_601191 != nil:
    section.add "X-Amz-Target", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Content-Sha256", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Algorithm")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Algorithm", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Signature")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Signature", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-SignedHeaders", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Credential")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Credential", valid_601196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601198: Call_GetAppReplicationConfiguration_601186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  let valid = call_601198.validator(path, query, header, formData, body)
  let scheme = call_601198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601198.url(scheme.get, call_601198.host, call_601198.base,
                         call_601198.route, valid.getOrDefault("path"))
  result = hook(call_601198, url, valid)

proc call*(call_601199: Call_GetAppReplicationConfiguration_601186; body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   body: JObject (required)
  var body_601200 = newJObject()
  if body != nil:
    body_601200 = body
  result = call_601199.call(nil, nil, nil, nil, body_601200)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_601186(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_601187, base: "/",
    url: url_GetAppReplicationConfiguration_601188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_601201 = ref object of OpenApiRestCall_600410
proc url_GetConnectors_601203(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConnectors_601202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601204 = query.getOrDefault("maxResults")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "maxResults", valid_601204
  var valid_601205 = query.getOrDefault("nextToken")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "nextToken", valid_601205
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
  var valid_601206 = header.getOrDefault("X-Amz-Date")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Date", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Security-Token")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Security-Token", valid_601207
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601208 = header.getOrDefault("X-Amz-Target")
  valid_601208 = validateParameter(valid_601208, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_601208 != nil:
    section.add "X-Amz-Target", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Content-Sha256", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Algorithm")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Algorithm", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Signature")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Signature", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-SignedHeaders", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Credential")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Credential", valid_601213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601215: Call_GetConnectors_601201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  let valid = call_601215.validator(path, query, header, formData, body)
  let scheme = call_601215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601215.url(scheme.get, call_601215.host, call_601215.base,
                         call_601215.route, valid.getOrDefault("path"))
  result = hook(call_601215, url, valid)

proc call*(call_601216: Call_GetConnectors_601201; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601217 = newJObject()
  var body_601218 = newJObject()
  add(query_601217, "maxResults", newJString(maxResults))
  add(query_601217, "nextToken", newJString(nextToken))
  if body != nil:
    body_601218 = body
  result = call_601216.call(nil, query_601217, nil, nil, body_601218)

var getConnectors* = Call_GetConnectors_601201(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_601202, base: "/", url: url_GetConnectors_601203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_601220 = ref object of OpenApiRestCall_600410
proc url_GetReplicationJobs_601222(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetReplicationJobs_601221(path: JsonNode; query: JsonNode;
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
  var valid_601223 = query.getOrDefault("maxResults")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "maxResults", valid_601223
  var valid_601224 = query.getOrDefault("nextToken")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "nextToken", valid_601224
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
  var valid_601225 = header.getOrDefault("X-Amz-Date")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Date", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Security-Token")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Security-Token", valid_601226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601227 = header.getOrDefault("X-Amz-Target")
  valid_601227 = validateParameter(valid_601227, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_601227 != nil:
    section.add "X-Amz-Target", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Content-Sha256", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Algorithm")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Algorithm", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Signature")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Signature", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-SignedHeaders", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Credential")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Credential", valid_601232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601234: Call_GetReplicationJobs_601220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  let valid = call_601234.validator(path, query, header, formData, body)
  let scheme = call_601234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601234.url(scheme.get, call_601234.host, call_601234.base,
                         call_601234.route, valid.getOrDefault("path"))
  result = hook(call_601234, url, valid)

proc call*(call_601235: Call_GetReplicationJobs_601220; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601236 = newJObject()
  var body_601237 = newJObject()
  add(query_601236, "maxResults", newJString(maxResults))
  add(query_601236, "nextToken", newJString(nextToken))
  if body != nil:
    body_601237 = body
  result = call_601235.call(nil, query_601236, nil, nil, body_601237)

var getReplicationJobs* = Call_GetReplicationJobs_601220(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_601221, base: "/",
    url: url_GetReplicationJobs_601222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_601238 = ref object of OpenApiRestCall_600410
proc url_GetReplicationRuns_601240(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetReplicationRuns_601239(path: JsonNode; query: JsonNode;
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
  var valid_601241 = query.getOrDefault("maxResults")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "maxResults", valid_601241
  var valid_601242 = query.getOrDefault("nextToken")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "nextToken", valid_601242
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
  var valid_601243 = header.getOrDefault("X-Amz-Date")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Date", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Security-Token")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Security-Token", valid_601244
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601245 = header.getOrDefault("X-Amz-Target")
  valid_601245 = validateParameter(valid_601245, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_601245 != nil:
    section.add "X-Amz-Target", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Content-Sha256", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Algorithm")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Algorithm", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Signature")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Signature", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-SignedHeaders", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Credential")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Credential", valid_601250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601252: Call_GetReplicationRuns_601238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the replication runs for the specified replication job.
  ## 
  let valid = call_601252.validator(path, query, header, formData, body)
  let scheme = call_601252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601252.url(scheme.get, call_601252.host, call_601252.base,
                         call_601252.route, valid.getOrDefault("path"))
  result = hook(call_601252, url, valid)

proc call*(call_601253: Call_GetReplicationRuns_601238; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601254 = newJObject()
  var body_601255 = newJObject()
  add(query_601254, "maxResults", newJString(maxResults))
  add(query_601254, "nextToken", newJString(nextToken))
  if body != nil:
    body_601255 = body
  result = call_601253.call(nil, query_601254, nil, nil, body_601255)

var getReplicationRuns* = Call_GetReplicationRuns_601238(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_601239, base: "/",
    url: url_GetReplicationRuns_601240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_601256 = ref object of OpenApiRestCall_600410
proc url_GetServers_601258(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServers_601257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601259 = query.getOrDefault("maxResults")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "maxResults", valid_601259
  var valid_601260 = query.getOrDefault("nextToken")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "nextToken", valid_601260
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
  var valid_601261 = header.getOrDefault("X-Amz-Date")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Date", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Security-Token")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Security-Token", valid_601262
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601263 = header.getOrDefault("X-Amz-Target")
  valid_601263 = validateParameter(valid_601263, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_601263 != nil:
    section.add "X-Amz-Target", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Content-Sha256", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Algorithm")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Algorithm", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Signature")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Signature", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-SignedHeaders", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Credential")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Credential", valid_601268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_GetServers_601256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"))
  result = hook(call_601270, url, valid)

proc call*(call_601271: Call_GetServers_601256; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601272 = newJObject()
  var body_601273 = newJObject()
  add(query_601272, "maxResults", newJString(maxResults))
  add(query_601272, "nextToken", newJString(nextToken))
  if body != nil:
    body_601273 = body
  result = call_601271.call(nil, query_601272, nil, nil, body_601273)

var getServers* = Call_GetServers_601256(name: "getServers",
                                      meth: HttpMethod.HttpPost,
                                      host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
                                      validator: validate_GetServers_601257,
                                      base: "/", url: url_GetServers_601258,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_601274 = ref object of OpenApiRestCall_600410
proc url_ImportServerCatalog_601276(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportServerCatalog_601275(path: JsonNode; query: JsonNode;
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
  var valid_601277 = header.getOrDefault("X-Amz-Date")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Date", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Security-Token")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Security-Token", valid_601278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601279 = header.getOrDefault("X-Amz-Target")
  valid_601279 = validateParameter(valid_601279, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_601279 != nil:
    section.add "X-Amz-Target", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Content-Sha256", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Algorithm")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Algorithm", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Signature")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Signature", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-SignedHeaders", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Credential")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Credential", valid_601284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601286: Call_ImportServerCatalog_601274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  let valid = call_601286.validator(path, query, header, formData, body)
  let scheme = call_601286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601286.url(scheme.get, call_601286.host, call_601286.base,
                         call_601286.route, valid.getOrDefault("path"))
  result = hook(call_601286, url, valid)

proc call*(call_601287: Call_ImportServerCatalog_601274; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   body: JObject (required)
  var body_601288 = newJObject()
  if body != nil:
    body_601288 = body
  result = call_601287.call(nil, nil, nil, nil, body_601288)

var importServerCatalog* = Call_ImportServerCatalog_601274(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_601275, base: "/",
    url: url_ImportServerCatalog_601276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_601289 = ref object of OpenApiRestCall_600410
proc url_LaunchApp_601291(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LaunchApp_601290(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601292 = header.getOrDefault("X-Amz-Date")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Date", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Security-Token")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Security-Token", valid_601293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601294 = header.getOrDefault("X-Amz-Target")
  valid_601294 = validateParameter(valid_601294, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_601294 != nil:
    section.add "X-Amz-Target", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Content-Sha256", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Algorithm")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Algorithm", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Signature")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Signature", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-SignedHeaders", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Credential")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Credential", valid_601299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601301: Call_LaunchApp_601289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an application stack.
  ## 
  let valid = call_601301.validator(path, query, header, formData, body)
  let scheme = call_601301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601301.url(scheme.get, call_601301.host, call_601301.base,
                         call_601301.route, valid.getOrDefault("path"))
  result = hook(call_601301, url, valid)

proc call*(call_601302: Call_LaunchApp_601289; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_601303 = newJObject()
  if body != nil:
    body_601303 = body
  result = call_601302.call(nil, nil, nil, nil, body_601303)

var launchApp* = Call_LaunchApp_601289(name: "launchApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
                                    validator: validate_LaunchApp_601290,
                                    base: "/", url: url_LaunchApp_601291,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_601304 = ref object of OpenApiRestCall_600410
proc url_ListApps_601306(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListApps_601305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601307 = header.getOrDefault("X-Amz-Date")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Date", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Security-Token")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Security-Token", valid_601308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601309 = header.getOrDefault("X-Amz-Target")
  valid_601309 = validateParameter(valid_601309, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_601309 != nil:
    section.add "X-Amz-Target", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Content-Sha256", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Algorithm")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Algorithm", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Signature")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Signature", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-SignedHeaders", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Credential")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Credential", valid_601314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601316: Call_ListApps_601304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of summaries for all applications.
  ## 
  let valid = call_601316.validator(path, query, header, formData, body)
  let scheme = call_601316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601316.url(scheme.get, call_601316.host, call_601316.base,
                         call_601316.route, valid.getOrDefault("path"))
  result = hook(call_601316, url, valid)

proc call*(call_601317: Call_ListApps_601304; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_601318 = newJObject()
  if body != nil:
    body_601318 = body
  result = call_601317.call(nil, nil, nil, nil, body_601318)

var listApps* = Call_ListApps_601304(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                  validator: validate_ListApps_601305, base: "/",
                                  url: url_ListApps_601306,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_601319 = ref object of OpenApiRestCall_600410
proc url_PutAppLaunchConfiguration_601321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAppLaunchConfiguration_601320(path: JsonNode; query: JsonNode;
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
  var valid_601322 = header.getOrDefault("X-Amz-Date")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Date", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Security-Token")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Security-Token", valid_601323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601324 = header.getOrDefault("X-Amz-Target")
  valid_601324 = validateParameter(valid_601324, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_601324 != nil:
    section.add "X-Amz-Target", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Content-Sha256", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Algorithm")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Algorithm", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Signature")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Signature", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-SignedHeaders", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Credential")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Credential", valid_601329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601331: Call_PutAppLaunchConfiguration_601319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a launch configuration for an application.
  ## 
  let valid = call_601331.validator(path, query, header, formData, body)
  let scheme = call_601331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601331.url(scheme.get, call_601331.host, call_601331.base,
                         call_601331.route, valid.getOrDefault("path"))
  result = hook(call_601331, url, valid)

proc call*(call_601332: Call_PutAppLaunchConfiguration_601319; body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_601333 = newJObject()
  if body != nil:
    body_601333 = body
  result = call_601332.call(nil, nil, nil, nil, body_601333)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_601319(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_601320, base: "/",
    url: url_PutAppLaunchConfiguration_601321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_601334 = ref object of OpenApiRestCall_600410
proc url_PutAppReplicationConfiguration_601336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAppReplicationConfiguration_601335(path: JsonNode;
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
  var valid_601337 = header.getOrDefault("X-Amz-Date")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Date", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Security-Token")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Security-Token", valid_601338
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601339 = header.getOrDefault("X-Amz-Target")
  valid_601339 = validateParameter(valid_601339, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_601339 != nil:
    section.add "X-Amz-Target", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Content-Sha256", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Algorithm")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Algorithm", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Signature")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Signature", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-SignedHeaders", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Credential")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Credential", valid_601344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601346: Call_PutAppReplicationConfiguration_601334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a replication configuration for an application.
  ## 
  let valid = call_601346.validator(path, query, header, formData, body)
  let scheme = call_601346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601346.url(scheme.get, call_601346.host, call_601346.base,
                         call_601346.route, valid.getOrDefault("path"))
  result = hook(call_601346, url, valid)

proc call*(call_601347: Call_PutAppReplicationConfiguration_601334; body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject (required)
  var body_601348 = newJObject()
  if body != nil:
    body_601348 = body
  result = call_601347.call(nil, nil, nil, nil, body_601348)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_601334(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_601335, base: "/",
    url: url_PutAppReplicationConfiguration_601336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_601349 = ref object of OpenApiRestCall_600410
proc url_StartAppReplication_601351(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAppReplication_601350(path: JsonNode; query: JsonNode;
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
  var valid_601352 = header.getOrDefault("X-Amz-Date")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Date", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Security-Token")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Security-Token", valid_601353
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601354 = header.getOrDefault("X-Amz-Target")
  valid_601354 = validateParameter(valid_601354, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_601354 != nil:
    section.add "X-Amz-Target", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Content-Sha256", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Algorithm")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Algorithm", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Signature")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Signature", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-SignedHeaders", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Credential")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Credential", valid_601359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601361: Call_StartAppReplication_601349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts replicating an application.
  ## 
  let valid = call_601361.validator(path, query, header, formData, body)
  let scheme = call_601361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601361.url(scheme.get, call_601361.host, call_601361.base,
                         call_601361.route, valid.getOrDefault("path"))
  result = hook(call_601361, url, valid)

proc call*(call_601362: Call_StartAppReplication_601349; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_601363 = newJObject()
  if body != nil:
    body_601363 = body
  result = call_601362.call(nil, nil, nil, nil, body_601363)

var startAppReplication* = Call_StartAppReplication_601349(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_601350, base: "/",
    url: url_StartAppReplication_601351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_601364 = ref object of OpenApiRestCall_600410
proc url_StartOnDemandReplicationRun_601366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartOnDemandReplicationRun_601365(path: JsonNode; query: JsonNode;
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
  var valid_601367 = header.getOrDefault("X-Amz-Date")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Date", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Security-Token")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Security-Token", valid_601368
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601369 = header.getOrDefault("X-Amz-Target")
  valid_601369 = validateParameter(valid_601369, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_601369 != nil:
    section.add "X-Amz-Target", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Content-Sha256", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Algorithm")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Algorithm", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Signature")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Signature", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-SignedHeaders", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Credential")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Credential", valid_601374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601376: Call_StartOnDemandReplicationRun_601364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  let valid = call_601376.validator(path, query, header, formData, body)
  let scheme = call_601376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601376.url(scheme.get, call_601376.host, call_601376.base,
                         call_601376.route, valid.getOrDefault("path"))
  result = hook(call_601376, url, valid)

proc call*(call_601377: Call_StartOnDemandReplicationRun_601364; body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_601378 = newJObject()
  if body != nil:
    body_601378 = body
  result = call_601377.call(nil, nil, nil, nil, body_601378)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_601364(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_601365, base: "/",
    url: url_StartOnDemandReplicationRun_601366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_601379 = ref object of OpenApiRestCall_600410
proc url_StopAppReplication_601381(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopAppReplication_601380(path: JsonNode; query: JsonNode;
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
  var valid_601382 = header.getOrDefault("X-Amz-Date")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Date", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Security-Token")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Security-Token", valid_601383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601384 = header.getOrDefault("X-Amz-Target")
  valid_601384 = validateParameter(valid_601384, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_601384 != nil:
    section.add "X-Amz-Target", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Content-Sha256", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Algorithm")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Algorithm", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Signature")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Signature", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-SignedHeaders", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Credential")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Credential", valid_601389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601391: Call_StopAppReplication_601379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops replicating an application.
  ## 
  let valid = call_601391.validator(path, query, header, formData, body)
  let scheme = call_601391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601391.url(scheme.get, call_601391.host, call_601391.base,
                         call_601391.route, valid.getOrDefault("path"))
  result = hook(call_601391, url, valid)

proc call*(call_601392: Call_StopAppReplication_601379; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_601393 = newJObject()
  if body != nil:
    body_601393 = body
  result = call_601392.call(nil, nil, nil, nil, body_601393)

var stopAppReplication* = Call_StopAppReplication_601379(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_601380, base: "/",
    url: url_StopAppReplication_601381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_601394 = ref object of OpenApiRestCall_600410
proc url_TerminateApp_601396(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TerminateApp_601395(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601397 = header.getOrDefault("X-Amz-Date")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Date", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Security-Token")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Security-Token", valid_601398
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601399 = header.getOrDefault("X-Amz-Target")
  valid_601399 = validateParameter(valid_601399, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_601399 != nil:
    section.add "X-Amz-Target", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Content-Sha256", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Algorithm")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Algorithm", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Signature")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Signature", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-SignedHeaders", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Credential")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Credential", valid_601404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601406: Call_TerminateApp_601394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the stack for an application.
  ## 
  let valid = call_601406.validator(path, query, header, formData, body)
  let scheme = call_601406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601406.url(scheme.get, call_601406.host, call_601406.base,
                         call_601406.route, valid.getOrDefault("path"))
  result = hook(call_601406, url, valid)

proc call*(call_601407: Call_TerminateApp_601394; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_601408 = newJObject()
  if body != nil:
    body_601408 = body
  result = call_601407.call(nil, nil, nil, nil, body_601408)

var terminateApp* = Call_TerminateApp_601394(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_601395, base: "/", url: url_TerminateApp_601396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_601409 = ref object of OpenApiRestCall_600410
proc url_UpdateApp_601411(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateApp_601410(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601412 = header.getOrDefault("X-Amz-Date")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Date", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Security-Token")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Security-Token", valid_601413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601414 = header.getOrDefault("X-Amz-Target")
  valid_601414 = validateParameter(valid_601414, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_601414 != nil:
    section.add "X-Amz-Target", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Content-Sha256", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Algorithm")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Algorithm", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Signature")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Signature", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-SignedHeaders", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Credential")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Credential", valid_601419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601421: Call_UpdateApp_601409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_601421.validator(path, query, header, formData, body)
  let scheme = call_601421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601421.url(scheme.get, call_601421.host, call_601421.base,
                         call_601421.route, valid.getOrDefault("path"))
  result = hook(call_601421, url, valid)

proc call*(call_601422: Call_UpdateApp_601409; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_601423 = newJObject()
  if body != nil:
    body_601423 = body
  result = call_601422.call(nil, nil, nil, nil, body_601423)

var updateApp* = Call_UpdateApp_601409(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
                                    validator: validate_UpdateApp_601410,
                                    base: "/", url: url_UpdateApp_601411,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_601424 = ref object of OpenApiRestCall_600410
proc url_UpdateReplicationJob_601426(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateReplicationJob_601425(path: JsonNode; query: JsonNode;
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
  var valid_601427 = header.getOrDefault("X-Amz-Date")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Date", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Security-Token")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Security-Token", valid_601428
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601429 = header.getOrDefault("X-Amz-Target")
  valid_601429 = validateParameter(valid_601429, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_601429 != nil:
    section.add "X-Amz-Target", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Content-Sha256", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Algorithm")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Algorithm", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Signature")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Signature", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-SignedHeaders", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Credential")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Credential", valid_601434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601436: Call_UpdateReplicationJob_601424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified settings for the specified replication job.
  ## 
  let valid = call_601436.validator(path, query, header, formData, body)
  let scheme = call_601436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601436.url(scheme.get, call_601436.host, call_601436.base,
                         call_601436.route, valid.getOrDefault("path"))
  result = hook(call_601436, url, valid)

proc call*(call_601437: Call_UpdateReplicationJob_601424; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_601438 = newJObject()
  if body != nil:
    body_601438 = body
  result = call_601437.call(nil, nil, nil, nil, body_601438)

var updateReplicationJob* = Call_UpdateReplicationJob_601424(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_601425, base: "/",
    url: url_UpdateReplicationJob_601426, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
