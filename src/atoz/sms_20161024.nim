
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApp_592687 = ref object of OpenApiRestCall_592348
proc url_CreateApp_592689(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateApp_592688(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592814 = header.getOrDefault("X-Amz-Target")
  valid_592814 = validateParameter(valid_592814, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_592814 != nil:
    section.add "X-Amz-Target", valid_592814
  var valid_592815 = header.getOrDefault("X-Amz-Signature")
  valid_592815 = validateParameter(valid_592815, JString, required = false,
                                 default = nil)
  if valid_592815 != nil:
    section.add "X-Amz-Signature", valid_592815
  var valid_592816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592816 = validateParameter(valid_592816, JString, required = false,
                                 default = nil)
  if valid_592816 != nil:
    section.add "X-Amz-Content-Sha256", valid_592816
  var valid_592817 = header.getOrDefault("X-Amz-Date")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Date", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Credential")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Credential", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Security-Token")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Security-Token", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Algorithm")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Algorithm", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-SignedHeaders", valid_592821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592845: Call_CreateApp_592687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ## 
  let valid = call_592845.validator(path, query, header, formData, body)
  let scheme = call_592845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592845.url(scheme.get, call_592845.host, call_592845.base,
                         call_592845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592845, url, valid)

proc call*(call_592916: Call_CreateApp_592687; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   body: JObject (required)
  var body_592917 = newJObject()
  if body != nil:
    body_592917 = body
  result = call_592916.call(nil, nil, nil, nil, body_592917)

var createApp* = Call_CreateApp_592687(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
                                    validator: validate_CreateApp_592688,
                                    base: "/", url: url_CreateApp_592689,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_592956 = ref object of OpenApiRestCall_592348
proc url_CreateReplicationJob_592958(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateReplicationJob_592957(path: JsonNode; query: JsonNode;
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
  var valid_592959 = header.getOrDefault("X-Amz-Target")
  valid_592959 = validateParameter(valid_592959, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_592959 != nil:
    section.add "X-Amz-Target", valid_592959
  var valid_592960 = header.getOrDefault("X-Amz-Signature")
  valid_592960 = validateParameter(valid_592960, JString, required = false,
                                 default = nil)
  if valid_592960 != nil:
    section.add "X-Amz-Signature", valid_592960
  var valid_592961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Content-Sha256", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Date")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Date", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Credential")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Credential", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Security-Token")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Security-Token", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Algorithm")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Algorithm", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-SignedHeaders", valid_592966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592968: Call_CreateReplicationJob_592956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ## 
  let valid = call_592968.validator(path, query, header, formData, body)
  let scheme = call_592968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592968.url(scheme.get, call_592968.host, call_592968.base,
                         call_592968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592968, url, valid)

proc call*(call_592969: Call_CreateReplicationJob_592956; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   body: JObject (required)
  var body_592970 = newJObject()
  if body != nil:
    body_592970 = body
  result = call_592969.call(nil, nil, nil, nil, body_592970)

var createReplicationJob* = Call_CreateReplicationJob_592956(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_592957, base: "/",
    url: url_CreateReplicationJob_592958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_592971 = ref object of OpenApiRestCall_592348
proc url_DeleteApp_592973(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteApp_592972(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592974 = header.getOrDefault("X-Amz-Target")
  valid_592974 = validateParameter(valid_592974, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_592974 != nil:
    section.add "X-Amz-Target", valid_592974
  var valid_592975 = header.getOrDefault("X-Amz-Signature")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Signature", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Content-Sha256", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Date")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Date", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Credential")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Credential", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Security-Token")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Security-Token", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Algorithm")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Algorithm", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-SignedHeaders", valid_592981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_DeleteApp_592971; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_DeleteApp_592971; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   body: JObject (required)
  var body_592985 = newJObject()
  if body != nil:
    body_592985 = body
  result = call_592984.call(nil, nil, nil, nil, body_592985)

var deleteApp* = Call_DeleteApp_592971(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
                                    validator: validate_DeleteApp_592972,
                                    base: "/", url: url_DeleteApp_592973,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_592986 = ref object of OpenApiRestCall_592348
proc url_DeleteAppLaunchConfiguration_592988(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAppLaunchConfiguration_592987(path: JsonNode; query: JsonNode;
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
  var valid_592989 = header.getOrDefault("X-Amz-Target")
  valid_592989 = validateParameter(valid_592989, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_592989 != nil:
    section.add "X-Amz-Target", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Signature")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Signature", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Content-Sha256", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Date")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Date", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Credential")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Credential", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Security-Token")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Security-Token", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-Algorithm")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-Algorithm", valid_592995
  var valid_592996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592996 = validateParameter(valid_592996, JString, required = false,
                                 default = nil)
  if valid_592996 != nil:
    section.add "X-Amz-SignedHeaders", valid_592996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592998: Call_DeleteAppLaunchConfiguration_592986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes existing launch configuration for an application.
  ## 
  let valid = call_592998.validator(path, query, header, formData, body)
  let scheme = call_592998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592998.url(scheme.get, call_592998.host, call_592998.base,
                         call_592998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592998, url, valid)

proc call*(call_592999: Call_DeleteAppLaunchConfiguration_592986; body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_593000 = newJObject()
  if body != nil:
    body_593000 = body
  result = call_592999.call(nil, nil, nil, nil, body_593000)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_592986(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_592987, base: "/",
    url: url_DeleteAppLaunchConfiguration_592988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_593001 = ref object of OpenApiRestCall_592348
proc url_DeleteAppReplicationConfiguration_593003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAppReplicationConfiguration_593002(path: JsonNode;
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
  var valid_593004 = header.getOrDefault("X-Amz-Target")
  valid_593004 = validateParameter(valid_593004, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_593004 != nil:
    section.add "X-Amz-Target", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Signature")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Signature", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Content-Sha256", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Date")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Date", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Credential")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Credential", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-Security-Token")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-Security-Token", valid_593009
  var valid_593010 = header.getOrDefault("X-Amz-Algorithm")
  valid_593010 = validateParameter(valid_593010, JString, required = false,
                                 default = nil)
  if valid_593010 != nil:
    section.add "X-Amz-Algorithm", valid_593010
  var valid_593011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593011 = validateParameter(valid_593011, JString, required = false,
                                 default = nil)
  if valid_593011 != nil:
    section.add "X-Amz-SignedHeaders", valid_593011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593013: Call_DeleteAppReplicationConfiguration_593001;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes existing replication configuration for an application.
  ## 
  let valid = call_593013.validator(path, query, header, formData, body)
  let scheme = call_593013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593013.url(scheme.get, call_593013.host, call_593013.base,
                         call_593013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593013, url, valid)

proc call*(call_593014: Call_DeleteAppReplicationConfiguration_593001;
          body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_593015 = newJObject()
  if body != nil:
    body_593015 = body
  result = call_593014.call(nil, nil, nil, nil, body_593015)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_593001(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_593002, base: "/",
    url: url_DeleteAppReplicationConfiguration_593003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_593016 = ref object of OpenApiRestCall_592348
proc url_DeleteReplicationJob_593018(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteReplicationJob_593017(path: JsonNode; query: JsonNode;
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
  var valid_593019 = header.getOrDefault("X-Amz-Target")
  valid_593019 = validateParameter(valid_593019, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_593019 != nil:
    section.add "X-Amz-Target", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Signature")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Signature", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Content-Sha256", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Date")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Date", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Credential")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Credential", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-Security-Token")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-Security-Token", valid_593024
  var valid_593025 = header.getOrDefault("X-Amz-Algorithm")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "X-Amz-Algorithm", valid_593025
  var valid_593026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "X-Amz-SignedHeaders", valid_593026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593028: Call_DeleteReplicationJob_593016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ## 
  let valid = call_593028.validator(path, query, header, formData, body)
  let scheme = call_593028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593028.url(scheme.get, call_593028.host, call_593028.base,
                         call_593028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593028, url, valid)

proc call*(call_593029: Call_DeleteReplicationJob_593016; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   body: JObject (required)
  var body_593030 = newJObject()
  if body != nil:
    body_593030 = body
  result = call_593029.call(nil, nil, nil, nil, body_593030)

var deleteReplicationJob* = Call_DeleteReplicationJob_593016(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_593017, base: "/",
    url: url_DeleteReplicationJob_593018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_593031 = ref object of OpenApiRestCall_592348
proc url_DeleteServerCatalog_593033(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteServerCatalog_593032(path: JsonNode; query: JsonNode;
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
  var valid_593034 = header.getOrDefault("X-Amz-Target")
  valid_593034 = validateParameter(valid_593034, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_593034 != nil:
    section.add "X-Amz-Target", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Signature")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Signature", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Content-Sha256", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Date")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Date", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Credential")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Credential", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Security-Token")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Security-Token", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Algorithm")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Algorithm", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-SignedHeaders", valid_593041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593043: Call_DeleteServerCatalog_593031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes all servers from your server catalog.
  ## 
  let valid = call_593043.validator(path, query, header, formData, body)
  let scheme = call_593043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593043.url(scheme.get, call_593043.host, call_593043.base,
                         call_593043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593043, url, valid)

proc call*(call_593044: Call_DeleteServerCatalog_593031; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_593045 = newJObject()
  if body != nil:
    body_593045 = body
  result = call_593044.call(nil, nil, nil, nil, body_593045)

var deleteServerCatalog* = Call_DeleteServerCatalog_593031(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_593032, base: "/",
    url: url_DeleteServerCatalog_593033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_593046 = ref object of OpenApiRestCall_592348
proc url_DisassociateConnector_593048(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateConnector_593047(path: JsonNode; query: JsonNode;
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
  var valid_593049 = header.getOrDefault("X-Amz-Target")
  valid_593049 = validateParameter(valid_593049, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_593049 != nil:
    section.add "X-Amz-Target", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Signature")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Signature", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Content-Sha256", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Date")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Date", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Credential")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Credential", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Security-Token")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Security-Token", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Algorithm")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Algorithm", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-SignedHeaders", valid_593056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593058: Call_DisassociateConnector_593046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ## 
  let valid = call_593058.validator(path, query, header, formData, body)
  let scheme = call_593058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593058.url(scheme.get, call_593058.host, call_593058.base,
                         call_593058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593058, url, valid)

proc call*(call_593059: Call_DisassociateConnector_593046; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   body: JObject (required)
  var body_593060 = newJObject()
  if body != nil:
    body_593060 = body
  result = call_593059.call(nil, nil, nil, nil, body_593060)

var disassociateConnector* = Call_DisassociateConnector_593046(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_593047, base: "/",
    url: url_DisassociateConnector_593048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_593061 = ref object of OpenApiRestCall_592348
proc url_GenerateChangeSet_593063(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateChangeSet_593062(path: JsonNode; query: JsonNode;
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
  var valid_593064 = header.getOrDefault("X-Amz-Target")
  valid_593064 = validateParameter(valid_593064, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_593064 != nil:
    section.add "X-Amz-Target", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Signature")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Signature", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-Content-Sha256", valid_593066
  var valid_593067 = header.getOrDefault("X-Amz-Date")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "X-Amz-Date", valid_593067
  var valid_593068 = header.getOrDefault("X-Amz-Credential")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Credential", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Security-Token")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Security-Token", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Algorithm")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Algorithm", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-SignedHeaders", valid_593071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593073: Call_GenerateChangeSet_593061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_593073.validator(path, query, header, formData, body)
  let scheme = call_593073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593073.url(scheme.get, call_593073.host, call_593073.base,
                         call_593073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593073, url, valid)

proc call*(call_593074: Call_GenerateChangeSet_593061; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_593075 = newJObject()
  if body != nil:
    body_593075 = body
  result = call_593074.call(nil, nil, nil, nil, body_593075)

var generateChangeSet* = Call_GenerateChangeSet_593061(name: "generateChangeSet",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_593062, base: "/",
    url: url_GenerateChangeSet_593063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_593076 = ref object of OpenApiRestCall_592348
proc url_GenerateTemplate_593078(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GenerateTemplate_593077(path: JsonNode; query: JsonNode;
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
  var valid_593079 = header.getOrDefault("X-Amz-Target")
  valid_593079 = validateParameter(valid_593079, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_593079 != nil:
    section.add "X-Amz-Target", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Signature")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Signature", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Content-Sha256", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Date")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Date", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Credential")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Credential", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Security-Token")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Security-Token", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Algorithm")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Algorithm", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-SignedHeaders", valid_593086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593088: Call_GenerateTemplate_593076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ## 
  let valid = call_593088.validator(path, query, header, formData, body)
  let scheme = call_593088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593088.url(scheme.get, call_593088.host, call_593088.base,
                         call_593088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593088, url, valid)

proc call*(call_593089: Call_GenerateTemplate_593076; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   body: JObject (required)
  var body_593090 = newJObject()
  if body != nil:
    body_593090 = body
  result = call_593089.call(nil, nil, nil, nil, body_593090)

var generateTemplate* = Call_GenerateTemplate_593076(name: "generateTemplate",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_593077, base: "/",
    url: url_GenerateTemplate_593078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_593091 = ref object of OpenApiRestCall_592348
proc url_GetApp_593093(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApp_593092(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593094 = header.getOrDefault("X-Amz-Target")
  valid_593094 = validateParameter(valid_593094, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_593094 != nil:
    section.add "X-Amz-Target", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Signature")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Signature", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Content-Sha256", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Date")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Date", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Credential")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Credential", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Security-Token")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Security-Token", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Algorithm")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Algorithm", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-SignedHeaders", valid_593101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593103: Call_GetApp_593091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve information about an application.
  ## 
  let valid = call_593103.validator(path, query, header, formData, body)
  let scheme = call_593103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593103.url(scheme.get, call_593103.host, call_593103.base,
                         call_593103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593103, url, valid)

proc call*(call_593104: Call_GetApp_593091; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_593105 = newJObject()
  if body != nil:
    body_593105 = body
  result = call_593104.call(nil, nil, nil, nil, body_593105)

var getApp* = Call_GetApp_593091(name: "getApp", meth: HttpMethod.HttpPost,
                              host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                              validator: validate_GetApp_593092, base: "/",
                              url: url_GetApp_593093,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_593106 = ref object of OpenApiRestCall_592348
proc url_GetAppLaunchConfiguration_593108(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAppLaunchConfiguration_593107(path: JsonNode; query: JsonNode;
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
  var valid_593109 = header.getOrDefault("X-Amz-Target")
  valid_593109 = validateParameter(valid_593109, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_593109 != nil:
    section.add "X-Amz-Target", valid_593109
  var valid_593110 = header.getOrDefault("X-Amz-Signature")
  valid_593110 = validateParameter(valid_593110, JString, required = false,
                                 default = nil)
  if valid_593110 != nil:
    section.add "X-Amz-Signature", valid_593110
  var valid_593111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Content-Sha256", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Date")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Date", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Credential")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Credential", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Security-Token")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Security-Token", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Algorithm")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Algorithm", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-SignedHeaders", valid_593116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593118: Call_GetAppLaunchConfiguration_593106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the application launch configuration associated with an application.
  ## 
  let valid = call_593118.validator(path, query, header, formData, body)
  let scheme = call_593118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593118.url(scheme.get, call_593118.host, call_593118.base,
                         call_593118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593118, url, valid)

proc call*(call_593119: Call_GetAppLaunchConfiguration_593106; body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   body: JObject (required)
  var body_593120 = newJObject()
  if body != nil:
    body_593120 = body
  result = call_593119.call(nil, nil, nil, nil, body_593120)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_593106(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_593107, base: "/",
    url: url_GetAppLaunchConfiguration_593108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_593121 = ref object of OpenApiRestCall_592348
proc url_GetAppReplicationConfiguration_593123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAppReplicationConfiguration_593122(path: JsonNode;
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
  var valid_593124 = header.getOrDefault("X-Amz-Target")
  valid_593124 = validateParameter(valid_593124, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_593124 != nil:
    section.add "X-Amz-Target", valid_593124
  var valid_593125 = header.getOrDefault("X-Amz-Signature")
  valid_593125 = validateParameter(valid_593125, JString, required = false,
                                 default = nil)
  if valid_593125 != nil:
    section.add "X-Amz-Signature", valid_593125
  var valid_593126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Content-Sha256", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Date")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Date", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Credential")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Credential", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Security-Token")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Security-Token", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Algorithm")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Algorithm", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-SignedHeaders", valid_593131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593133: Call_GetAppReplicationConfiguration_593121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
  ## 
  let valid = call_593133.validator(path, query, header, formData, body)
  let scheme = call_593133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593133.url(scheme.get, call_593133.host, call_593133.base,
                         call_593133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593133, url, valid)

proc call*(call_593134: Call_GetAppReplicationConfiguration_593121; body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   body: JObject (required)
  var body_593135 = newJObject()
  if body != nil:
    body_593135 = body
  result = call_593134.call(nil, nil, nil, nil, body_593135)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_593121(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_593122, base: "/",
    url: url_GetAppReplicationConfiguration_593123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_593136 = ref object of OpenApiRestCall_592348
proc url_GetConnectors_593138(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConnectors_593137(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593139 = query.getOrDefault("nextToken")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "nextToken", valid_593139
  var valid_593140 = query.getOrDefault("maxResults")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "maxResults", valid_593140
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
  var valid_593141 = header.getOrDefault("X-Amz-Target")
  valid_593141 = validateParameter(valid_593141, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_593141 != nil:
    section.add "X-Amz-Target", valid_593141
  var valid_593142 = header.getOrDefault("X-Amz-Signature")
  valid_593142 = validateParameter(valid_593142, JString, required = false,
                                 default = nil)
  if valid_593142 != nil:
    section.add "X-Amz-Signature", valid_593142
  var valid_593143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Content-Sha256", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Date")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Date", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Credential")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Credential", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Security-Token")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Security-Token", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Algorithm")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Algorithm", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-SignedHeaders", valid_593148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593150: Call_GetConnectors_593136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the connectors registered with the AWS SMS.
  ## 
  let valid = call_593150.validator(path, query, header, formData, body)
  let scheme = call_593150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593150.url(scheme.get, call_593150.host, call_593150.base,
                         call_593150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593150, url, valid)

proc call*(call_593151: Call_GetConnectors_593136; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593152 = newJObject()
  var body_593153 = newJObject()
  add(query_593152, "nextToken", newJString(nextToken))
  if body != nil:
    body_593153 = body
  add(query_593152, "maxResults", newJString(maxResults))
  result = call_593151.call(nil, query_593152, nil, nil, body_593153)

var getConnectors* = Call_GetConnectors_593136(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_593137, base: "/", url: url_GetConnectors_593138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_593155 = ref object of OpenApiRestCall_592348
proc url_GetReplicationJobs_593157(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetReplicationJobs_593156(path: JsonNode; query: JsonNode;
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
  var valid_593158 = query.getOrDefault("nextToken")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "nextToken", valid_593158
  var valid_593159 = query.getOrDefault("maxResults")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "maxResults", valid_593159
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
  var valid_593160 = header.getOrDefault("X-Amz-Target")
  valid_593160 = validateParameter(valid_593160, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_593160 != nil:
    section.add "X-Amz-Target", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Signature")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Signature", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Content-Sha256", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Date")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Date", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Credential")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Credential", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Security-Token")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Security-Token", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Algorithm")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Algorithm", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-SignedHeaders", valid_593167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593169: Call_GetReplicationJobs_593155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
  ## 
  let valid = call_593169.validator(path, query, header, formData, body)
  let scheme = call_593169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593169.url(scheme.get, call_593169.host, call_593169.base,
                         call_593169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593169, url, valid)

proc call*(call_593170: Call_GetReplicationJobs_593155; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593171 = newJObject()
  var body_593172 = newJObject()
  add(query_593171, "nextToken", newJString(nextToken))
  if body != nil:
    body_593172 = body
  add(query_593171, "maxResults", newJString(maxResults))
  result = call_593170.call(nil, query_593171, nil, nil, body_593172)

var getReplicationJobs* = Call_GetReplicationJobs_593155(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_593156, base: "/",
    url: url_GetReplicationJobs_593157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_593173 = ref object of OpenApiRestCall_592348
proc url_GetReplicationRuns_593175(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetReplicationRuns_593174(path: JsonNode; query: JsonNode;
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
  var valid_593176 = query.getOrDefault("nextToken")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "nextToken", valid_593176
  var valid_593177 = query.getOrDefault("maxResults")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "maxResults", valid_593177
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
  var valid_593178 = header.getOrDefault("X-Amz-Target")
  valid_593178 = validateParameter(valid_593178, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_593178 != nil:
    section.add "X-Amz-Target", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Signature")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Signature", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Content-Sha256", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Date")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Date", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Credential")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Credential", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Security-Token")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Security-Token", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Algorithm")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Algorithm", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-SignedHeaders", valid_593185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593187: Call_GetReplicationRuns_593173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the replication runs for the specified replication job.
  ## 
  let valid = call_593187.validator(path, query, header, formData, body)
  let scheme = call_593187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593187.url(scheme.get, call_593187.host, call_593187.base,
                         call_593187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593187, url, valid)

proc call*(call_593188: Call_GetReplicationRuns_593173; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593189 = newJObject()
  var body_593190 = newJObject()
  add(query_593189, "nextToken", newJString(nextToken))
  if body != nil:
    body_593190 = body
  add(query_593189, "maxResults", newJString(maxResults))
  result = call_593188.call(nil, query_593189, nil, nil, body_593190)

var getReplicationRuns* = Call_GetReplicationRuns_593173(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_593174, base: "/",
    url: url_GetReplicationRuns_593175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_593191 = ref object of OpenApiRestCall_592348
proc url_GetServers_593193(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetServers_593192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593194 = query.getOrDefault("nextToken")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "nextToken", valid_593194
  var valid_593195 = query.getOrDefault("maxResults")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "maxResults", valid_593195
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
  var valid_593196 = header.getOrDefault("X-Amz-Target")
  valid_593196 = validateParameter(valid_593196, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_593196 != nil:
    section.add "X-Amz-Target", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-Signature")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Signature", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Content-Sha256", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Date")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Date", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Credential")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Credential", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Security-Token")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Security-Token", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Algorithm")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Algorithm", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-SignedHeaders", valid_593203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593205: Call_GetServers_593191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ## 
  let valid = call_593205.validator(path, query, header, formData, body)
  let scheme = call_593205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593205.url(scheme.get, call_593205.host, call_593205.base,
                         call_593205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593205, url, valid)

proc call*(call_593206: Call_GetServers_593191; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593207 = newJObject()
  var body_593208 = newJObject()
  add(query_593207, "nextToken", newJString(nextToken))
  if body != nil:
    body_593208 = body
  add(query_593207, "maxResults", newJString(maxResults))
  result = call_593206.call(nil, query_593207, nil, nil, body_593208)

var getServers* = Call_GetServers_593191(name: "getServers",
                                      meth: HttpMethod.HttpPost,
                                      host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
                                      validator: validate_GetServers_593192,
                                      base: "/", url: url_GetServers_593193,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_593209 = ref object of OpenApiRestCall_592348
proc url_ImportServerCatalog_593211(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportServerCatalog_593210(path: JsonNode; query: JsonNode;
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
  var valid_593212 = header.getOrDefault("X-Amz-Target")
  valid_593212 = validateParameter(valid_593212, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_593212 != nil:
    section.add "X-Amz-Target", valid_593212
  var valid_593213 = header.getOrDefault("X-Amz-Signature")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Signature", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Content-Sha256", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Date")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Date", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Credential")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Credential", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Security-Token")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Security-Token", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Algorithm")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Algorithm", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-SignedHeaders", valid_593219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593221: Call_ImportServerCatalog_593209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ## 
  let valid = call_593221.validator(path, query, header, formData, body)
  let scheme = call_593221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593221.url(scheme.get, call_593221.host, call_593221.base,
                         call_593221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593221, url, valid)

proc call*(call_593222: Call_ImportServerCatalog_593209; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   body: JObject (required)
  var body_593223 = newJObject()
  if body != nil:
    body_593223 = body
  result = call_593222.call(nil, nil, nil, nil, body_593223)

var importServerCatalog* = Call_ImportServerCatalog_593209(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_593210, base: "/",
    url: url_ImportServerCatalog_593211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_593224 = ref object of OpenApiRestCall_592348
proc url_LaunchApp_593226(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_LaunchApp_593225(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593227 = header.getOrDefault("X-Amz-Target")
  valid_593227 = validateParameter(valid_593227, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_593227 != nil:
    section.add "X-Amz-Target", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Signature")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Signature", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Content-Sha256", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Date")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Date", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Credential")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Credential", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Security-Token")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Security-Token", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Algorithm")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Algorithm", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-SignedHeaders", valid_593234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593236: Call_LaunchApp_593224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an application stack.
  ## 
  let valid = call_593236.validator(path, query, header, formData, body)
  let scheme = call_593236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593236.url(scheme.get, call_593236.host, call_593236.base,
                         call_593236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593236, url, valid)

proc call*(call_593237: Call_LaunchApp_593224; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_593238 = newJObject()
  if body != nil:
    body_593238 = body
  result = call_593237.call(nil, nil, nil, nil, body_593238)

var launchApp* = Call_LaunchApp_593224(name: "launchApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
                                    validator: validate_LaunchApp_593225,
                                    base: "/", url: url_LaunchApp_593226,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_593239 = ref object of OpenApiRestCall_592348
proc url_ListApps_593241(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListApps_593240(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593242 = header.getOrDefault("X-Amz-Target")
  valid_593242 = validateParameter(valid_593242, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_593242 != nil:
    section.add "X-Amz-Target", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Signature")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Signature", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Content-Sha256", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Date")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Date", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Credential")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Credential", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-Security-Token")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-Security-Token", valid_593247
  var valid_593248 = header.getOrDefault("X-Amz-Algorithm")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Algorithm", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-SignedHeaders", valid_593249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593251: Call_ListApps_593239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of summaries for all applications.
  ## 
  let valid = call_593251.validator(path, query, header, formData, body)
  let scheme = call_593251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593251.url(scheme.get, call_593251.host, call_593251.base,
                         call_593251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593251, url, valid)

proc call*(call_593252: Call_ListApps_593239; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_593253 = newJObject()
  if body != nil:
    body_593253 = body
  result = call_593252.call(nil, nil, nil, nil, body_593253)

var listApps* = Call_ListApps_593239(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                  validator: validate_ListApps_593240, base: "/",
                                  url: url_ListApps_593241,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_593254 = ref object of OpenApiRestCall_592348
proc url_PutAppLaunchConfiguration_593256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutAppLaunchConfiguration_593255(path: JsonNode; query: JsonNode;
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
  var valid_593257 = header.getOrDefault("X-Amz-Target")
  valid_593257 = validateParameter(valid_593257, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_593257 != nil:
    section.add "X-Amz-Target", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Signature")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Signature", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Content-Sha256", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Date")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Date", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Credential")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Credential", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Security-Token")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Security-Token", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-Algorithm")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Algorithm", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-SignedHeaders", valid_593264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593266: Call_PutAppLaunchConfiguration_593254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a launch configuration for an application.
  ## 
  let valid = call_593266.validator(path, query, header, formData, body)
  let scheme = call_593266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593266.url(scheme.get, call_593266.host, call_593266.base,
                         call_593266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593266, url, valid)

proc call*(call_593267: Call_PutAppLaunchConfiguration_593254; body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_593268 = newJObject()
  if body != nil:
    body_593268 = body
  result = call_593267.call(nil, nil, nil, nil, body_593268)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_593254(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_593255, base: "/",
    url: url_PutAppLaunchConfiguration_593256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_593269 = ref object of OpenApiRestCall_592348
proc url_PutAppReplicationConfiguration_593271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutAppReplicationConfiguration_593270(path: JsonNode;
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
  var valid_593272 = header.getOrDefault("X-Amz-Target")
  valid_593272 = validateParameter(valid_593272, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_593272 != nil:
    section.add "X-Amz-Target", valid_593272
  var valid_593273 = header.getOrDefault("X-Amz-Signature")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "X-Amz-Signature", valid_593273
  var valid_593274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "X-Amz-Content-Sha256", valid_593274
  var valid_593275 = header.getOrDefault("X-Amz-Date")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Date", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Credential")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Credential", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Security-Token")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Security-Token", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Algorithm")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Algorithm", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-SignedHeaders", valid_593279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593281: Call_PutAppReplicationConfiguration_593269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a replication configuration for an application.
  ## 
  let valid = call_593281.validator(path, query, header, formData, body)
  let scheme = call_593281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593281.url(scheme.get, call_593281.host, call_593281.base,
                         call_593281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593281, url, valid)

proc call*(call_593282: Call_PutAppReplicationConfiguration_593269; body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject (required)
  var body_593283 = newJObject()
  if body != nil:
    body_593283 = body
  result = call_593282.call(nil, nil, nil, nil, body_593283)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_593269(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_593270, base: "/",
    url: url_PutAppReplicationConfiguration_593271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_593284 = ref object of OpenApiRestCall_592348
proc url_StartAppReplication_593286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartAppReplication_593285(path: JsonNode; query: JsonNode;
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
  var valid_593287 = header.getOrDefault("X-Amz-Target")
  valid_593287 = validateParameter(valid_593287, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_593287 != nil:
    section.add "X-Amz-Target", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-Signature")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-Signature", valid_593288
  var valid_593289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593289 = validateParameter(valid_593289, JString, required = false,
                                 default = nil)
  if valid_593289 != nil:
    section.add "X-Amz-Content-Sha256", valid_593289
  var valid_593290 = header.getOrDefault("X-Amz-Date")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "X-Amz-Date", valid_593290
  var valid_593291 = header.getOrDefault("X-Amz-Credential")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Credential", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Security-Token")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Security-Token", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Algorithm")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Algorithm", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-SignedHeaders", valid_593294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593296: Call_StartAppReplication_593284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts replicating an application.
  ## 
  let valid = call_593296.validator(path, query, header, formData, body)
  let scheme = call_593296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593296.url(scheme.get, call_593296.host, call_593296.base,
                         call_593296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593296, url, valid)

proc call*(call_593297: Call_StartAppReplication_593284; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_593298 = newJObject()
  if body != nil:
    body_593298 = body
  result = call_593297.call(nil, nil, nil, nil, body_593298)

var startAppReplication* = Call_StartAppReplication_593284(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_593285, base: "/",
    url: url_StartAppReplication_593286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_593299 = ref object of OpenApiRestCall_592348
proc url_StartOnDemandReplicationRun_593301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartOnDemandReplicationRun_593300(path: JsonNode; query: JsonNode;
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
  var valid_593302 = header.getOrDefault("X-Amz-Target")
  valid_593302 = validateParameter(valid_593302, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_593302 != nil:
    section.add "X-Amz-Target", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-Signature")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-Signature", valid_593303
  var valid_593304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593304 = validateParameter(valid_593304, JString, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "X-Amz-Content-Sha256", valid_593304
  var valid_593305 = header.getOrDefault("X-Amz-Date")
  valid_593305 = validateParameter(valid_593305, JString, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "X-Amz-Date", valid_593305
  var valid_593306 = header.getOrDefault("X-Amz-Credential")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "X-Amz-Credential", valid_593306
  var valid_593307 = header.getOrDefault("X-Amz-Security-Token")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "X-Amz-Security-Token", valid_593307
  var valid_593308 = header.getOrDefault("X-Amz-Algorithm")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "X-Amz-Algorithm", valid_593308
  var valid_593309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-SignedHeaders", valid_593309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593311: Call_StartOnDemandReplicationRun_593299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ## 
  let valid = call_593311.validator(path, query, header, formData, body)
  let scheme = call_593311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593311.url(scheme.get, call_593311.host, call_593311.base,
                         call_593311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593311, url, valid)

proc call*(call_593312: Call_StartOnDemandReplicationRun_593299; body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   body: JObject (required)
  var body_593313 = newJObject()
  if body != nil:
    body_593313 = body
  result = call_593312.call(nil, nil, nil, nil, body_593313)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_593299(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_593300, base: "/",
    url: url_StartOnDemandReplicationRun_593301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_593314 = ref object of OpenApiRestCall_592348
proc url_StopAppReplication_593316(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopAppReplication_593315(path: JsonNode; query: JsonNode;
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
  var valid_593317 = header.getOrDefault("X-Amz-Target")
  valid_593317 = validateParameter(valid_593317, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_593317 != nil:
    section.add "X-Amz-Target", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Signature")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Signature", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Content-Sha256", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Date")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Date", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Credential")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Credential", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Security-Token")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Security-Token", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-Algorithm")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-Algorithm", valid_593323
  var valid_593324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "X-Amz-SignedHeaders", valid_593324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593326: Call_StopAppReplication_593314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops replicating an application.
  ## 
  let valid = call_593326.validator(path, query, header, formData, body)
  let scheme = call_593326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593326.url(scheme.get, call_593326.host, call_593326.base,
                         call_593326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593326, url, valid)

proc call*(call_593327: Call_StopAppReplication_593314; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_593328 = newJObject()
  if body != nil:
    body_593328 = body
  result = call_593327.call(nil, nil, nil, nil, body_593328)

var stopAppReplication* = Call_StopAppReplication_593314(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_593315, base: "/",
    url: url_StopAppReplication_593316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_593329 = ref object of OpenApiRestCall_592348
proc url_TerminateApp_593331(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateApp_593330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593332 = header.getOrDefault("X-Amz-Target")
  valid_593332 = validateParameter(valid_593332, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_593332 != nil:
    section.add "X-Amz-Target", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Signature")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Signature", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Content-Sha256", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Date")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Date", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Credential")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Credential", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Security-Token")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Security-Token", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-Algorithm")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-Algorithm", valid_593338
  var valid_593339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593339 = validateParameter(valid_593339, JString, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "X-Amz-SignedHeaders", valid_593339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593341: Call_TerminateApp_593329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the stack for an application.
  ## 
  let valid = call_593341.validator(path, query, header, formData, body)
  let scheme = call_593341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593341.url(scheme.get, call_593341.host, call_593341.base,
                         call_593341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593341, url, valid)

proc call*(call_593342: Call_TerminateApp_593329; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_593343 = newJObject()
  if body != nil:
    body_593343 = body
  result = call_593342.call(nil, nil, nil, nil, body_593343)

var terminateApp* = Call_TerminateApp_593329(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_593330, base: "/", url: url_TerminateApp_593331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_593344 = ref object of OpenApiRestCall_592348
proc url_UpdateApp_593346(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateApp_593345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593347 = header.getOrDefault("X-Amz-Target")
  valid_593347 = validateParameter(valid_593347, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_593347 != nil:
    section.add "X-Amz-Target", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Signature")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Signature", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Content-Sha256", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Date")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Date", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Credential")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Credential", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Security-Token")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Security-Token", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Algorithm")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Algorithm", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-SignedHeaders", valid_593354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593356: Call_UpdateApp_593344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an application.
  ## 
  let valid = call_593356.validator(path, query, header, formData, body)
  let scheme = call_593356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593356.url(scheme.get, call_593356.host, call_593356.base,
                         call_593356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593356, url, valid)

proc call*(call_593357: Call_UpdateApp_593344; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_593358 = newJObject()
  if body != nil:
    body_593358 = body
  result = call_593357.call(nil, nil, nil, nil, body_593358)

var updateApp* = Call_UpdateApp_593344(name: "updateApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
                                    validator: validate_UpdateApp_593345,
                                    base: "/", url: url_UpdateApp_593346,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_593359 = ref object of OpenApiRestCall_592348
proc url_UpdateReplicationJob_593361(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateReplicationJob_593360(path: JsonNode; query: JsonNode;
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
  var valid_593362 = header.getOrDefault("X-Amz-Target")
  valid_593362 = validateParameter(valid_593362, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_593362 != nil:
    section.add "X-Amz-Target", valid_593362
  var valid_593363 = header.getOrDefault("X-Amz-Signature")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Signature", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Content-Sha256", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Date")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Date", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Credential")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Credential", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Security-Token")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Security-Token", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Algorithm")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Algorithm", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-SignedHeaders", valid_593369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593371: Call_UpdateReplicationJob_593359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified settings for the specified replication job.
  ## 
  let valid = call_593371.validator(path, query, header, formData, body)
  let scheme = call_593371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593371.url(scheme.get, call_593371.host, call_593371.base,
                         call_593371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593371, url, valid)

proc call*(call_593372: Call_UpdateReplicationJob_593359; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_593373 = newJObject()
  if body != nil:
    body_593373 = body
  result = call_593372.call(nil, nil, nil, nil, body_593373)

var updateReplicationJob* = Call_UpdateReplicationJob_593359(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_593360, base: "/",
    url: url_UpdateReplicationJob_593361, schemes: {Scheme.Https, Scheme.Http})
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
