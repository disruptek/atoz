
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

  OpenApiRestCall_772581 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772581](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772581): Option[Scheme] {.used.} =
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
  Call_CreateApp_772917 = ref object of OpenApiRestCall_772581
proc url_CreateApp_772919(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApp_772918(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773031 = header.getOrDefault("X-Amz-Date")
  valid_773031 = validateParameter(valid_773031, JString, required = false,
                                 default = nil)
  if valid_773031 != nil:
    section.add "X-Amz-Date", valid_773031
  var valid_773032 = header.getOrDefault("X-Amz-Security-Token")
  valid_773032 = validateParameter(valid_773032, JString, required = false,
                                 default = nil)
  if valid_773032 != nil:
    section.add "X-Amz-Security-Token", valid_773032
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773046 = header.getOrDefault("X-Amz-Target")
  valid_773046 = validateParameter(valid_773046, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_773046 != nil:
    section.add "X-Amz-Target", valid_773046
  var valid_773047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Content-Sha256", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Algorithm")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Algorithm", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Signature")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Signature", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-SignedHeaders", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Credential")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Credential", valid_773051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773075: Call_CreateApp_772917; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  let valid = call_773075.validator(path, query, header, formData, body)
  let scheme = call_773075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773075.url(scheme.get, call_773075.host, call_773075.base,
                         call_773075.route, valid.getOrDefault("path"))
  result = hook(call_773075, url, valid)

proc call*(call_773146: Call_CreateApp_772917; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   body: JObject (required)
  var body_773147 = newJObject()
  if body != nil:
    body_773147 = body
  result = call_773146.call(nil, nil, nil, nil, body_773147)

var createApp* = Call_CreateApp_772917(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
                                    validator: validate_CreateApp_772918,
                                    base: "/", url: url_CreateApp_772919,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_773186 = ref object of OpenApiRestCall_772581
proc url_CreateReplicationJob_773188(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationJob_773187(path: JsonNode; query: JsonNode;
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
  var valid_773189 = header.getOrDefault("X-Amz-Date")
  valid_773189 = validateParameter(valid_773189, JString, required = false,
                                 default = nil)
  if valid_773189 != nil:
    section.add "X-Amz-Date", valid_773189
  var valid_773190 = header.getOrDefault("X-Amz-Security-Token")
  valid_773190 = validateParameter(valid_773190, JString, required = false,
                                 default = nil)
  if valid_773190 != nil:
    section.add "X-Amz-Security-Token", valid_773190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773191 = header.getOrDefault("X-Amz-Target")
  valid_773191 = validateParameter(valid_773191, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_773191 != nil:
    section.add "X-Amz-Target", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Content-Sha256", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-Algorithm")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Algorithm", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Signature")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Signature", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-SignedHeaders", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Credential")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Credential", valid_773196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773198: Call_CreateReplicationJob_773186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  let valid = call_773198.validator(path, query, header, formData, body)
  let scheme = call_773198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773198.url(scheme.get, call_773198.host, call_773198.base,
                         call_773198.route, valid.getOrDefault("path"))
  result = hook(call_773198, url, valid)

proc call*(call_773199: Call_CreateReplicationJob_773186; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   body: JObject (required)
  var body_773200 = newJObject()
  if body != nil:
    body_773200 = body
  result = call_773199.call(nil, nil, nil, nil, body_773200)

var createReplicationJob* = Call_CreateReplicationJob_773186(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_773187, base: "/",
    url: url_CreateReplicationJob_773188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_773201 = ref object of OpenApiRestCall_772581
proc url_DeleteApp_773203(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteApp_773202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773204 = header.getOrDefault("X-Amz-Date")
  valid_773204 = validateParameter(valid_773204, JString, required = false,
                                 default = nil)
  if valid_773204 != nil:
    section.add "X-Amz-Date", valid_773204
  var valid_773205 = header.getOrDefault("X-Amz-Security-Token")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Security-Token", valid_773205
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773206 = header.getOrDefault("X-Amz-Target")
  valid_773206 = validateParameter(valid_773206, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_773206 != nil:
    section.add "X-Amz-Target", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Content-Sha256", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Algorithm")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Algorithm", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Signature")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Signature", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-SignedHeaders", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Credential")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Credential", valid_773211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773213: Call_DeleteApp_773201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  let valid = call_773213.validator(path, query, header, formData, body)
  let scheme = call_773213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773213.url(scheme.get, call_773213.host, call_773213.base,
                         call_773213.route, valid.getOrDefault("path"))
  result = hook(call_773213, url, valid)

proc call*(call_773214: Call_DeleteApp_773201; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   body: JObject (required)
  var body_773215 = newJObject()
  if body != nil:
    body_773215 = body
  result = call_773214.call(nil, nil, nil, nil, body_773215)

var deleteApp* = Call_DeleteApp_773201(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
                                    validator: validate_DeleteApp_773202,
                                    base: "/", url: url_DeleteApp_773203,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_773216 = ref object of OpenApiRestCall_772581
proc url_DeleteAppLaunchConfiguration_773218(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAppLaunchConfiguration_773217(path: JsonNode; query: JsonNode;
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
  var valid_773219 = header.getOrDefault("X-Amz-Date")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Date", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Security-Token")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Security-Token", valid_773220
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773221 = header.getOrDefault("X-Amz-Target")
  valid_773221 = validateParameter(valid_773221, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_773221 != nil:
    section.add "X-Amz-Target", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Content-Sha256", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Algorithm")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Algorithm", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Signature")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Signature", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-SignedHeaders", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Credential")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Credential", valid_773226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773228: Call_DeleteAppLaunchConfiguration_773216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes existing launch configuration for an application.
  ## 
  let valid = call_773228.validator(path, query, header, formData, body)
  let scheme = call_773228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773228.url(scheme.get, call_773228.host, call_773228.base,
                         call_773228.route, valid.getOrDefault("path"))
  result = hook(call_773228, url, valid)

proc call*(call_773229: Call_DeleteAppLaunchConfiguration_773216; body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_773230 = newJObject()
  if body != nil:
    body_773230 = body
  result = call_773229.call(nil, nil, nil, nil, body_773230)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_773216(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_773217, base: "/",
    url: url_DeleteAppLaunchConfiguration_773218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_773231 = ref object of OpenApiRestCall_772581
proc url_DeleteAppReplicationConfiguration_773233(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAppReplicationConfiguration_773232(path: JsonNode;
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
  var valid_773234 = header.getOrDefault("X-Amz-Date")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Date", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Security-Token")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Security-Token", valid_773235
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773236 = header.getOrDefault("X-Amz-Target")
  valid_773236 = validateParameter(valid_773236, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_773236 != nil:
    section.add "X-Amz-Target", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Content-Sha256", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Algorithm")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Algorithm", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Signature")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Signature", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-SignedHeaders", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Credential")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Credential", valid_773241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773243: Call_DeleteAppReplicationConfiguration_773231;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes existing replication configuration for an application.
  ## 
  let valid = call_773243.validator(path, query, header, formData, body)
  let scheme = call_773243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773243.url(scheme.get, call_773243.host, call_773243.base,
                         call_773243.route, valid.getOrDefault("path"))
  result = hook(call_773243, url, valid)

proc call*(call_773244: Call_DeleteAppReplicationConfiguration_773231;
          body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_773245 = newJObject()
  if body != nil:
    body_773245 = body
  result = call_773244.call(nil, nil, nil, nil, body_773245)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_773231(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_773232, base: "/",
    url: url_DeleteAppReplicationConfiguration_773233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_773246 = ref object of OpenApiRestCall_772581
proc url_DeleteReplicationJob_773248(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationJob_773247(path: JsonNode; query: JsonNode;
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
  var valid_773249 = header.getOrDefault("X-Amz-Date")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Date", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Security-Token")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Security-Token", valid_773250
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773251 = header.getOrDefault("X-Amz-Target")
  valid_773251 = validateParameter(valid_773251, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_773251 != nil:
    section.add "X-Amz-Target", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Content-Sha256", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Algorithm")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Algorithm", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Signature")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Signature", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-SignedHeaders", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Credential")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Credential", valid_773256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773258: Call_DeleteReplicationJob_773246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  let valid = call_773258.validator(path, query, header, formData, body)
  let scheme = call_773258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773258.url(scheme.get, call_773258.host, call_773258.base,
                         call_773258.route, valid.getOrDefault("path"))
  result = hook(call_773258, url, valid)

proc call*(call_773259: Call_DeleteReplicationJob_773246; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   body: JObject (required)
  var body_773260 = newJObject()
  if body != nil:
    body_773260 = body
  result = call_773259.call(nil, nil, nil, nil, body_773260)

var deleteReplicationJob* = Call_DeleteReplicationJob_773246(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_773247, base: "/",
    url: url_DeleteReplicationJob_773248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_773261 = ref object of OpenApiRestCall_772581
proc url_DeleteServerCatalog_773263(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteServerCatalog_773262(path: JsonNode; query: JsonNode;
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
  var valid_773264 = header.getOrDefault("X-Amz-Date")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-Date", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Security-Token")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Security-Token", valid_773265
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773266 = header.getOrDefault("X-Amz-Target")
  valid_773266 = validateParameter(valid_773266, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_773266 != nil:
    section.add "X-Amz-Target", valid_773266
  var valid_773267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Content-Sha256", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Algorithm")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Algorithm", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Signature")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Signature", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-SignedHeaders", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Credential")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Credential", valid_773271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773273: Call_DeleteServerCatalog_773261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all servers from your server catalog.
  ## 
  let valid = call_773273.validator(path, query, header, formData, body)
  let scheme = call_773273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773273.url(scheme.get, call_773273.host, call_773273.base,
                         call_773273.route, valid.getOrDefault("path"))
  result = hook(call_773273, url, valid)

proc call*(call_773274: Call_DeleteServerCatalog_773261; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_773275 = newJObject()
  if body != nil:
    body_773275 = body
  result = call_773274.call(nil, nil, nil, nil, body_773275)

var deleteServerCatalog* = Call_DeleteServerCatalog_773261(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_773262, base: "/",
    url: url_DeleteServerCatalog_773263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_773276 = ref object of OpenApiRestCall_772581
proc url_DisassociateConnector_773278(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateConnector_773277(path: JsonNode; query: JsonNode;
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
  var valid_773279 = header.getOrDefault("X-Amz-Date")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Date", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Security-Token")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Security-Token", valid_773280
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773281 = header.getOrDefault("X-Amz-Target")
  valid_773281 = validateParameter(valid_773281, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_773281 != nil:
    section.add "X-Amz-Target", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Content-Sha256", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Algorithm")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Algorithm", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Signature")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Signature", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-SignedHeaders", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Credential")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Credential", valid_773286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773288: Call_DisassociateConnector_773276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  let valid = call_773288.validator(path, query, header, formData, body)
  let scheme = call_773288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773288.url(scheme.get, call_773288.host, call_773288.base,
                         call_773288.route, valid.getOrDefault("path"))
  result = hook(call_773288, url, valid)

proc call*(call_773289: Call_DisassociateConnector_773276; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   body: JObject (required)
  var body_773290 = newJObject()
  if body != nil:
    body_773290 = body
  result = call_773289.call(nil, nil, nil, nil, body_773290)

var disassociateConnector* = Call_DisassociateConnector_773276(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_773277, base: "/",
    url: url_DisassociateConnector_773278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_773291 = ref object of OpenApiRestCall_772581
proc url_GenerateChangeSet_773293(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateChangeSet_773292(path: JsonNode; query: JsonNode;
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
  var valid_773294 = header.getOrDefault("X-Amz-Date")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Date", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Security-Token")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Security-Token", valid_773295
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773296 = header.getOrDefault("X-Amz-Target")
  valid_773296 = validateParameter(valid_773296, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_773296 != nil:
    section.add "X-Amz-Target", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Content-Sha256", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Algorithm")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Algorithm", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Signature")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Signature", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-SignedHeaders", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-Credential")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-Credential", valid_773301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773303: Call_GenerateChangeSet_773291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_773303.validator(path, query, header, formData, body)
  let scheme = call_773303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773303.url(scheme.get, call_773303.host, call_773303.base,
                         call_773303.route, valid.getOrDefault("path"))
  result = hook(call_773303, url, valid)

proc call*(call_773304: Call_GenerateChangeSet_773291; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_773305 = newJObject()
  if body != nil:
    body_773305 = body
  result = call_773304.call(nil, nil, nil, nil, body_773305)

var generateChangeSet* = Call_GenerateChangeSet_773291(name: "generateChangeSet",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_773292, base: "/",
    url: url_GenerateChangeSet_773293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_773306 = ref object of OpenApiRestCall_772581
proc url_GenerateTemplate_773308(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GenerateTemplate_773307(path: JsonNode; query: JsonNode;
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
  var valid_773309 = header.getOrDefault("X-Amz-Date")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Date", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Security-Token")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Security-Token", valid_773310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773311 = header.getOrDefault("X-Amz-Target")
  valid_773311 = validateParameter(valid_773311, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_773311 != nil:
    section.add "X-Amz-Target", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Content-Sha256", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Algorithm")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Algorithm", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Signature")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Signature", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-SignedHeaders", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-Credential")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-Credential", valid_773316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773318: Call_GenerateTemplate_773306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_773318.validator(path, query, header, formData, body)
  let scheme = call_773318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773318.url(scheme.get, call_773318.host, call_773318.base,
                         call_773318.route, valid.getOrDefault("path"))
  result = hook(call_773318, url, valid)

proc call*(call_773319: Call_GenerateTemplate_773306; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_773320 = newJObject()
  if body != nil:
    body_773320 = body
  result = call_773319.call(nil, nil, nil, nil, body_773320)

var generateTemplate* = Call_GenerateTemplate_773306(name: "generateTemplate",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_773307, base: "/",
    url: url_GenerateTemplate_773308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_773321 = ref object of OpenApiRestCall_772581
proc url_GetApp_773323(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApp_773322(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773324 = header.getOrDefault("X-Amz-Date")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Date", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Security-Token")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Security-Token", valid_773325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773326 = header.getOrDefault("X-Amz-Target")
  valid_773326 = validateParameter(valid_773326, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_773326 != nil:
    section.add "X-Amz-Target", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Content-Sha256", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Algorithm")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Algorithm", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Signature")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Signature", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-SignedHeaders", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Credential")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Credential", valid_773331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773333: Call_GetApp_773321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_773333.validator(path, query, header, formData, body)
  let scheme = call_773333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773333.url(scheme.get, call_773333.host, call_773333.base,
                         call_773333.route, valid.getOrDefault("path"))
  result = hook(call_773333, url, valid)

proc call*(call_773334: Call_GetApp_773321; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_773335 = newJObject()
  if body != nil:
    body_773335 = body
  result = call_773334.call(nil, nil, nil, nil, body_773335)

var getApp* = Call_GetApp_773321(name: "getApp", meth: HttpMethod.HttpPost,
                              host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                              validator: validate_GetApp_773322, base: "/",
                              url: url_GetApp_773323,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_773336 = ref object of OpenApiRestCall_772581
proc url_GetAppLaunchConfiguration_773338(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAppLaunchConfiguration_773337(path: JsonNode; query: JsonNode;
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
  var valid_773339 = header.getOrDefault("X-Amz-Date")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Date", valid_773339
  var valid_773340 = header.getOrDefault("X-Amz-Security-Token")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Security-Token", valid_773340
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773341 = header.getOrDefault("X-Amz-Target")
  valid_773341 = validateParameter(valid_773341, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_773341 != nil:
    section.add "X-Amz-Target", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Content-Sha256", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Algorithm")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Algorithm", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Signature")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Signature", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-SignedHeaders", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Credential")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Credential", valid_773346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773348: Call_GetAppLaunchConfiguration_773336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  let valid = call_773348.validator(path, query, header, formData, body)
  let scheme = call_773348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773348.url(scheme.get, call_773348.host, call_773348.base,
                         call_773348.route, valid.getOrDefault("path"))
  result = hook(call_773348, url, valid)

proc call*(call_773349: Call_GetAppLaunchConfiguration_773336; body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   body: JObject (required)
  var body_773350 = newJObject()
  if body != nil:
    body_773350 = body
  result = call_773349.call(nil, nil, nil, nil, body_773350)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_773336(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_773337, base: "/",
    url: url_GetAppLaunchConfiguration_773338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_773351 = ref object of OpenApiRestCall_772581
proc url_GetAppReplicationConfiguration_773353(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAppReplicationConfiguration_773352(path: JsonNode;
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
  var valid_773354 = header.getOrDefault("X-Amz-Date")
  valid_773354 = validateParameter(valid_773354, JString, required = false,
                                 default = nil)
  if valid_773354 != nil:
    section.add "X-Amz-Date", valid_773354
  var valid_773355 = header.getOrDefault("X-Amz-Security-Token")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Security-Token", valid_773355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773356 = header.getOrDefault("X-Amz-Target")
  valid_773356 = validateParameter(valid_773356, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_773356 != nil:
    section.add "X-Amz-Target", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Content-Sha256", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Algorithm")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Algorithm", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Signature")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Signature", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-SignedHeaders", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Credential")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Credential", valid_773361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773363: Call_GetAppReplicationConfiguration_773351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  let valid = call_773363.validator(path, query, header, formData, body)
  let scheme = call_773363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773363.url(scheme.get, call_773363.host, call_773363.base,
                         call_773363.route, valid.getOrDefault("path"))
  result = hook(call_773363, url, valid)

proc call*(call_773364: Call_GetAppReplicationConfiguration_773351; body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   body: JObject (required)
  var body_773365 = newJObject()
  if body != nil:
    body_773365 = body
  result = call_773364.call(nil, nil, nil, nil, body_773365)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_773351(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_773352, base: "/",
    url: url_GetAppReplicationConfiguration_773353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_773366 = ref object of OpenApiRestCall_772581
proc url_GetConnectors_773368(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConnectors_773367(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773369 = query.getOrDefault("maxResults")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "maxResults", valid_773369
  var valid_773370 = query.getOrDefault("nextToken")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "nextToken", valid_773370
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
  var valid_773371 = header.getOrDefault("X-Amz-Date")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Date", valid_773371
  var valid_773372 = header.getOrDefault("X-Amz-Security-Token")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Security-Token", valid_773372
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773373 = header.getOrDefault("X-Amz-Target")
  valid_773373 = validateParameter(valid_773373, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_773373 != nil:
    section.add "X-Amz-Target", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Content-Sha256", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Algorithm")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Algorithm", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Signature")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Signature", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-SignedHeaders", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Credential")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Credential", valid_773378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773380: Call_GetConnectors_773366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  let valid = call_773380.validator(path, query, header, formData, body)
  let scheme = call_773380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773380.url(scheme.get, call_773380.host, call_773380.base,
                         call_773380.route, valid.getOrDefault("path"))
  result = hook(call_773380, url, valid)

proc call*(call_773381: Call_GetConnectors_773366; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773382 = newJObject()
  var body_773383 = newJObject()
  add(query_773382, "maxResults", newJString(maxResults))
  add(query_773382, "nextToken", newJString(nextToken))
  if body != nil:
    body_773383 = body
  result = call_773381.call(nil, query_773382, nil, nil, body_773383)

var getConnectors* = Call_GetConnectors_773366(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_773367, base: "/", url: url_GetConnectors_773368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_773385 = ref object of OpenApiRestCall_772581
proc url_GetReplicationJobs_773387(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetReplicationJobs_773386(path: JsonNode; query: JsonNode;
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
  var valid_773388 = query.getOrDefault("maxResults")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "maxResults", valid_773388
  var valid_773389 = query.getOrDefault("nextToken")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "nextToken", valid_773389
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
  var valid_773390 = header.getOrDefault("X-Amz-Date")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Date", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Security-Token")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Security-Token", valid_773391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773392 = header.getOrDefault("X-Amz-Target")
  valid_773392 = validateParameter(valid_773392, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_773392 != nil:
    section.add "X-Amz-Target", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Content-Sha256", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Algorithm")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Algorithm", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Signature")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Signature", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-SignedHeaders", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Credential")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Credential", valid_773397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773399: Call_GetReplicationJobs_773385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  let valid = call_773399.validator(path, query, header, formData, body)
  let scheme = call_773399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773399.url(scheme.get, call_773399.host, call_773399.base,
                         call_773399.route, valid.getOrDefault("path"))
  result = hook(call_773399, url, valid)

proc call*(call_773400: Call_GetReplicationJobs_773385; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773401 = newJObject()
  var body_773402 = newJObject()
  add(query_773401, "maxResults", newJString(maxResults))
  add(query_773401, "nextToken", newJString(nextToken))
  if body != nil:
    body_773402 = body
  result = call_773400.call(nil, query_773401, nil, nil, body_773402)

var getReplicationJobs* = Call_GetReplicationJobs_773385(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_773386, base: "/",
    url: url_GetReplicationJobs_773387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_773403 = ref object of OpenApiRestCall_772581
proc url_GetReplicationRuns_773405(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetReplicationRuns_773404(path: JsonNode; query: JsonNode;
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
  var valid_773406 = query.getOrDefault("maxResults")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "maxResults", valid_773406
  var valid_773407 = query.getOrDefault("nextToken")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "nextToken", valid_773407
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
  var valid_773408 = header.getOrDefault("X-Amz-Date")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Date", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Security-Token")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Security-Token", valid_773409
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773410 = header.getOrDefault("X-Amz-Target")
  valid_773410 = validateParameter(valid_773410, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_773410 != nil:
    section.add "X-Amz-Target", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Content-Sha256", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Algorithm")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Algorithm", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Signature")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Signature", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-SignedHeaders", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Credential")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Credential", valid_773415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773417: Call_GetReplicationRuns_773403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the replication runs for the specified replication job.
  ## 
  let valid = call_773417.validator(path, query, header, formData, body)
  let scheme = call_773417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773417.url(scheme.get, call_773417.host, call_773417.base,
                         call_773417.route, valid.getOrDefault("path"))
  result = hook(call_773417, url, valid)

proc call*(call_773418: Call_GetReplicationRuns_773403; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773419 = newJObject()
  var body_773420 = newJObject()
  add(query_773419, "maxResults", newJString(maxResults))
  add(query_773419, "nextToken", newJString(nextToken))
  if body != nil:
    body_773420 = body
  result = call_773418.call(nil, query_773419, nil, nil, body_773420)

var getReplicationRuns* = Call_GetReplicationRuns_773403(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_773404, base: "/",
    url: url_GetReplicationRuns_773405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_773421 = ref object of OpenApiRestCall_772581
proc url_GetServers_773423(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetServers_773422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773424 = query.getOrDefault("maxResults")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "maxResults", valid_773424
  var valid_773425 = query.getOrDefault("nextToken")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "nextToken", valid_773425
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
  var valid_773426 = header.getOrDefault("X-Amz-Date")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Date", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-Security-Token")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Security-Token", valid_773427
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773428 = header.getOrDefault("X-Amz-Target")
  valid_773428 = validateParameter(valid_773428, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_773428 != nil:
    section.add "X-Amz-Target", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Content-Sha256", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Algorithm")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Algorithm", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Signature")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Signature", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-SignedHeaders", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Credential")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Credential", valid_773433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773435: Call_GetServers_773421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  let valid = call_773435.validator(path, query, header, formData, body)
  let scheme = call_773435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773435.url(scheme.get, call_773435.host, call_773435.base,
                         call_773435.route, valid.getOrDefault("path"))
  result = hook(call_773435, url, valid)

proc call*(call_773436: Call_GetServers_773421; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_773437 = newJObject()
  var body_773438 = newJObject()
  add(query_773437, "maxResults", newJString(maxResults))
  add(query_773437, "nextToken", newJString(nextToken))
  if body != nil:
    body_773438 = body
  result = call_773436.call(nil, query_773437, nil, nil, body_773438)

var getServers* = Call_GetServers_773421(name: "getServers",
                                      meth: HttpMethod.HttpPost,
                                      host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
                                      validator: validate_GetServers_773422,
                                      base: "/", url: url_GetServers_773423,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_773439 = ref object of OpenApiRestCall_772581
proc url_ImportServerCatalog_773441(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportServerCatalog_773440(path: JsonNode; query: JsonNode;
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
  var valid_773442 = header.getOrDefault("X-Amz-Date")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Date", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Security-Token")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Security-Token", valid_773443
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773444 = header.getOrDefault("X-Amz-Target")
  valid_773444 = validateParameter(valid_773444, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_773444 != nil:
    section.add "X-Amz-Target", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Content-Sha256", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Algorithm")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Algorithm", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Signature")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Signature", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-SignedHeaders", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Credential")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Credential", valid_773449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773451: Call_ImportServerCatalog_773439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  let valid = call_773451.validator(path, query, header, formData, body)
  let scheme = call_773451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773451.url(scheme.get, call_773451.host, call_773451.base,
                         call_773451.route, valid.getOrDefault("path"))
  result = hook(call_773451, url, valid)

proc call*(call_773452: Call_ImportServerCatalog_773439; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   body: JObject (required)
  var body_773453 = newJObject()
  if body != nil:
    body_773453 = body
  result = call_773452.call(nil, nil, nil, nil, body_773453)

var importServerCatalog* = Call_ImportServerCatalog_773439(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_773440, base: "/",
    url: url_ImportServerCatalog_773441, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_773454 = ref object of OpenApiRestCall_772581
proc url_LaunchApp_773456(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_LaunchApp_773455(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773457 = header.getOrDefault("X-Amz-Date")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Date", valid_773457
  var valid_773458 = header.getOrDefault("X-Amz-Security-Token")
  valid_773458 = validateParameter(valid_773458, JString, required = false,
                                 default = nil)
  if valid_773458 != nil:
    section.add "X-Amz-Security-Token", valid_773458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773459 = header.getOrDefault("X-Amz-Target")
  valid_773459 = validateParameter(valid_773459, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_773459 != nil:
    section.add "X-Amz-Target", valid_773459
  var valid_773460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Content-Sha256", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Algorithm")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Algorithm", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Signature")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Signature", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-SignedHeaders", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Credential")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Credential", valid_773464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773466: Call_LaunchApp_773454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an application stack.
  ## 
  let valid = call_773466.validator(path, query, header, formData, body)
  let scheme = call_773466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773466.url(scheme.get, call_773466.host, call_773466.base,
                         call_773466.route, valid.getOrDefault("path"))
  result = hook(call_773466, url, valid)

proc call*(call_773467: Call_LaunchApp_773454; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_773468 = newJObject()
  if body != nil:
    body_773468 = body
  result = call_773467.call(nil, nil, nil, nil, body_773468)

var launchApp* = Call_LaunchApp_773454(name: "launchApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
                                    validator: validate_LaunchApp_773455,
                                    base: "/", url: url_LaunchApp_773456,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_773469 = ref object of OpenApiRestCall_772581
proc url_ListApps_773471(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListApps_773470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773472 = header.getOrDefault("X-Amz-Date")
  valid_773472 = validateParameter(valid_773472, JString, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "X-Amz-Date", valid_773472
  var valid_773473 = header.getOrDefault("X-Amz-Security-Token")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Security-Token", valid_773473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773474 = header.getOrDefault("X-Amz-Target")
  valid_773474 = validateParameter(valid_773474, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_773474 != nil:
    section.add "X-Amz-Target", valid_773474
  var valid_773475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Content-Sha256", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Algorithm")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Algorithm", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-Signature")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Signature", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-SignedHeaders", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Credential")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Credential", valid_773479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773481: Call_ListApps_773469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of summaries for all applications.
  ## 
  let valid = call_773481.validator(path, query, header, formData, body)
  let scheme = call_773481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773481.url(scheme.get, call_773481.host, call_773481.base,
                         call_773481.route, valid.getOrDefault("path"))
  result = hook(call_773481, url, valid)

proc call*(call_773482: Call_ListApps_773469; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_773483 = newJObject()
  if body != nil:
    body_773483 = body
  result = call_773482.call(nil, nil, nil, nil, body_773483)

var listApps* = Call_ListApps_773469(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                  validator: validate_ListApps_773470, base: "/",
                                  url: url_ListApps_773471,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_773484 = ref object of OpenApiRestCall_772581
proc url_PutAppLaunchConfiguration_773486(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAppLaunchConfiguration_773485(path: JsonNode; query: JsonNode;
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
  var valid_773487 = header.getOrDefault("X-Amz-Date")
  valid_773487 = validateParameter(valid_773487, JString, required = false,
                                 default = nil)
  if valid_773487 != nil:
    section.add "X-Amz-Date", valid_773487
  var valid_773488 = header.getOrDefault("X-Amz-Security-Token")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "X-Amz-Security-Token", valid_773488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773489 = header.getOrDefault("X-Amz-Target")
  valid_773489 = validateParameter(valid_773489, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_773489 != nil:
    section.add "X-Amz-Target", valid_773489
  var valid_773490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Content-Sha256", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Algorithm")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Algorithm", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Signature")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Signature", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-SignedHeaders", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Credential")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Credential", valid_773494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773496: Call_PutAppLaunchConfiguration_773484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a launch configuration for an application.
  ## 
  let valid = call_773496.validator(path, query, header, formData, body)
  let scheme = call_773496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773496.url(scheme.get, call_773496.host, call_773496.base,
                         call_773496.route, valid.getOrDefault("path"))
  result = hook(call_773496, url, valid)

proc call*(call_773497: Call_PutAppLaunchConfiguration_773484; body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_773498 = newJObject()
  if body != nil:
    body_773498 = body
  result = call_773497.call(nil, nil, nil, nil, body_773498)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_773484(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_773485, base: "/",
    url: url_PutAppLaunchConfiguration_773486,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_773499 = ref object of OpenApiRestCall_772581
proc url_PutAppReplicationConfiguration_773501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAppReplicationConfiguration_773500(path: JsonNode;
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
  var valid_773502 = header.getOrDefault("X-Amz-Date")
  valid_773502 = validateParameter(valid_773502, JString, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "X-Amz-Date", valid_773502
  var valid_773503 = header.getOrDefault("X-Amz-Security-Token")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "X-Amz-Security-Token", valid_773503
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773504 = header.getOrDefault("X-Amz-Target")
  valid_773504 = validateParameter(valid_773504, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_773504 != nil:
    section.add "X-Amz-Target", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Content-Sha256", valid_773505
  var valid_773506 = header.getOrDefault("X-Amz-Algorithm")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Algorithm", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Signature")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Signature", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-SignedHeaders", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Credential")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Credential", valid_773509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773511: Call_PutAppReplicationConfiguration_773499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a replication configuration for an application.
  ## 
  let valid = call_773511.validator(path, query, header, formData, body)
  let scheme = call_773511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773511.url(scheme.get, call_773511.host, call_773511.base,
                         call_773511.route, valid.getOrDefault("path"))
  result = hook(call_773511, url, valid)

proc call*(call_773512: Call_PutAppReplicationConfiguration_773499; body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject (required)
  var body_773513 = newJObject()
  if body != nil:
    body_773513 = body
  result = call_773512.call(nil, nil, nil, nil, body_773513)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_773499(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_773500, base: "/",
    url: url_PutAppReplicationConfiguration_773501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_773514 = ref object of OpenApiRestCall_772581
proc url_StartAppReplication_773516(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAppReplication_773515(path: JsonNode; query: JsonNode;
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
  var valid_773517 = header.getOrDefault("X-Amz-Date")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-Date", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Security-Token")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Security-Token", valid_773518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773519 = header.getOrDefault("X-Amz-Target")
  valid_773519 = validateParameter(valid_773519, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_773519 != nil:
    section.add "X-Amz-Target", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Content-Sha256", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Algorithm")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Algorithm", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Signature")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Signature", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-SignedHeaders", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Credential")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Credential", valid_773524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773526: Call_StartAppReplication_773514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts replicating an application.
  ## 
  let valid = call_773526.validator(path, query, header, formData, body)
  let scheme = call_773526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773526.url(scheme.get, call_773526.host, call_773526.base,
                         call_773526.route, valid.getOrDefault("path"))
  result = hook(call_773526, url, valid)

proc call*(call_773527: Call_StartAppReplication_773514; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_773528 = newJObject()
  if body != nil:
    body_773528 = body
  result = call_773527.call(nil, nil, nil, nil, body_773528)

var startAppReplication* = Call_StartAppReplication_773514(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_773515, base: "/",
    url: url_StartAppReplication_773516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_773529 = ref object of OpenApiRestCall_772581
proc url_StartOnDemandReplicationRun_773531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartOnDemandReplicationRun_773530(path: JsonNode; query: JsonNode;
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
  var valid_773532 = header.getOrDefault("X-Amz-Date")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-Date", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Security-Token")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Security-Token", valid_773533
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773534 = header.getOrDefault("X-Amz-Target")
  valid_773534 = validateParameter(valid_773534, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_773534 != nil:
    section.add "X-Amz-Target", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Content-Sha256", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Algorithm")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Algorithm", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Signature")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Signature", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-SignedHeaders", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-Credential")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-Credential", valid_773539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773541: Call_StartOnDemandReplicationRun_773529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  let valid = call_773541.validator(path, query, header, formData, body)
  let scheme = call_773541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773541.url(scheme.get, call_773541.host, call_773541.base,
                         call_773541.route, valid.getOrDefault("path"))
  result = hook(call_773541, url, valid)

proc call*(call_773542: Call_StartOnDemandReplicationRun_773529; body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_773543 = newJObject()
  if body != nil:
    body_773543 = body
  result = call_773542.call(nil, nil, nil, nil, body_773543)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_773529(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_773530, base: "/",
    url: url_StartOnDemandReplicationRun_773531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_773544 = ref object of OpenApiRestCall_772581
proc url_StopAppReplication_773546(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopAppReplication_773545(path: JsonNode; query: JsonNode;
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
  var valid_773547 = header.getOrDefault("X-Amz-Date")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Date", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Security-Token")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Security-Token", valid_773548
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773549 = header.getOrDefault("X-Amz-Target")
  valid_773549 = validateParameter(valid_773549, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_773549 != nil:
    section.add "X-Amz-Target", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Content-Sha256", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Algorithm")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Algorithm", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Signature")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Signature", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-SignedHeaders", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Credential")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Credential", valid_773554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773556: Call_StopAppReplication_773544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops replicating an application.
  ## 
  let valid = call_773556.validator(path, query, header, formData, body)
  let scheme = call_773556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773556.url(scheme.get, call_773556.host, call_773556.base,
                         call_773556.route, valid.getOrDefault("path"))
  result = hook(call_773556, url, valid)

proc call*(call_773557: Call_StopAppReplication_773544; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_773558 = newJObject()
  if body != nil:
    body_773558 = body
  result = call_773557.call(nil, nil, nil, nil, body_773558)

var stopAppReplication* = Call_StopAppReplication_773544(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_773545, base: "/",
    url: url_StopAppReplication_773546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_773559 = ref object of OpenApiRestCall_772581
proc url_TerminateApp_773561(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TerminateApp_773560(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773562 = header.getOrDefault("X-Amz-Date")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Date", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Security-Token")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Security-Token", valid_773563
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773564 = header.getOrDefault("X-Amz-Target")
  valid_773564 = validateParameter(valid_773564, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_773564 != nil:
    section.add "X-Amz-Target", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Content-Sha256", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Algorithm")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Algorithm", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Signature")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Signature", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-SignedHeaders", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Credential")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Credential", valid_773569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773571: Call_TerminateApp_773559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the stack for an application.
  ## 
  let valid = call_773571.validator(path, query, header, formData, body)
  let scheme = call_773571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773571.url(scheme.get, call_773571.host, call_773571.base,
                         call_773571.route, valid.getOrDefault("path"))
  result = hook(call_773571, url, valid)

proc call*(call_773572: Call_TerminateApp_773559; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_773573 = newJObject()
  if body != nil:
    body_773573 = body
  result = call_773572.call(nil, nil, nil, nil, body_773573)

var terminateApp* = Call_TerminateApp_773559(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_773560, base: "/", url: url_TerminateApp_773561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_773574 = ref object of OpenApiRestCall_772581
proc url_UpdateApp_773576(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateApp_773575(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773577 = header.getOrDefault("X-Amz-Date")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Date", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Security-Token")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Security-Token", valid_773578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773579 = header.getOrDefault("X-Amz-Target")
  valid_773579 = validateParameter(valid_773579, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_773579 != nil:
    section.add "X-Amz-Target", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Content-Sha256", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Algorithm")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Algorithm", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Signature")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Signature", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-SignedHeaders", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Credential")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Credential", valid_773584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773586: Call_UpdateApp_773574; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_773586.validator(path, query, header, formData, body)
  let scheme = call_773586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773586.url(scheme.get, call_773586.host, call_773586.base,
                         call_773586.route, valid.getOrDefault("path"))
  result = hook(call_773586, url, valid)

proc call*(call_773587: Call_UpdateApp_773574; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_773588 = newJObject()
  if body != nil:
    body_773588 = body
  result = call_773587.call(nil, nil, nil, nil, body_773588)

var updateApp* = Call_UpdateApp_773574(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
                                    validator: validate_UpdateApp_773575,
                                    base: "/", url: url_UpdateApp_773576,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_773589 = ref object of OpenApiRestCall_772581
proc url_UpdateReplicationJob_773591(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateReplicationJob_773590(path: JsonNode; query: JsonNode;
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
  var valid_773592 = header.getOrDefault("X-Amz-Date")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Date", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-Security-Token")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Security-Token", valid_773593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773594 = header.getOrDefault("X-Amz-Target")
  valid_773594 = validateParameter(valid_773594, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_773594 != nil:
    section.add "X-Amz-Target", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Content-Sha256", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Algorithm")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Algorithm", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Signature")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Signature", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-SignedHeaders", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Credential")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Credential", valid_773599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773601: Call_UpdateReplicationJob_773589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified settings for the specified replication job.
  ## 
  let valid = call_773601.validator(path, query, header, formData, body)
  let scheme = call_773601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773601.url(scheme.get, call_773601.host, call_773601.base,
                         call_773601.route, valid.getOrDefault("path"))
  result = hook(call_773601, url, valid)

proc call*(call_773602: Call_UpdateReplicationJob_773589; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_773603 = newJObject()
  if body != nil:
    body_773603 = body
  result = call_773602.call(nil, nil, nil, nil, body_773603)

var updateReplicationJob* = Call_UpdateReplicationJob_773589(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_773590, base: "/",
    url: url_UpdateReplicationJob_773591, schemes: {Scheme.Https, Scheme.Http})
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
