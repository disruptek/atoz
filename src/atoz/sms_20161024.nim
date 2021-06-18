
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656035 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656035](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656035): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "sms.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sms.ap-southeast-1.amazonaws.com",
                               "us-west-2": "sms.us-west-2.amazonaws.com",
                               "eu-west-2": "sms.eu-west-2.amazonaws.com", "ap-northeast-3": "sms.ap-northeast-3.amazonaws.com", "eu-central-1": "sms.eu-central-1.amazonaws.com",
                               "us-east-2": "sms.us-east-2.amazonaws.com",
                               "us-east-1": "sms.us-east-1.amazonaws.com", "cn-northwest-1": "sms.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "sms.ap-south-1.amazonaws.com",
                               "eu-north-1": "sms.eu-north-1.amazonaws.com", "ap-northeast-2": "sms.ap-northeast-2.amazonaws.com",
                               "us-west-1": "sms.us-west-1.amazonaws.com", "us-gov-east-1": "sms.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "sms.eu-west-3.amazonaws.com",
                               "cn-north-1": "sms.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "sms.sa-east-1.amazonaws.com",
                               "eu-west-1": "sms.eu-west-1.amazonaws.com", "us-gov-west-1": "sms.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sms.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "sms.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateApp_402656285 = ref object of OpenApiRestCall_402656035
proc url_CreateApp_402656287(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_402656286(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656381 = header.getOrDefault("X-Amz-Target")
  valid_402656381 = validateParameter(valid_402656381, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateApp"))
  if valid_402656381 != nil:
    section.add "X-Amz-Target", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Security-Token", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Signature")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Signature", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Algorithm", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Date")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Date", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Credential")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Credential", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656388
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

proc call*(call_402656403: Call_CreateApp_402656285; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
                                                                                         ## 
  let valid = call_402656403.validator(path, query, header, formData, body, _)
  let scheme = call_402656403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656403.makeUrl(scheme.get, call_402656403.host, call_402656403.base,
                                   call_402656403.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656403, uri, valid, _)

proc call*(call_402656452: Call_CreateApp_402656285; body: JsonNode): Recallable =
  ## createApp
  ## Creates an application. An application consists of one or more server groups. Each server group contain one or more servers.
  ##   
                                                                                                                                 ## body: JObject (required)
  var body_402656453 = newJObject()
  if body != nil:
    body_402656453 = body
  result = call_402656452.call(nil, nil, nil, nil, body_402656453)

var createApp* = Call_CreateApp_402656285(name: "createApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateApp",
    validator: validate_CreateApp_402656286, base: "/", makeUrl: url_CreateApp_402656287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationJob_402656480 = ref object of OpenApiRestCall_402656035
proc url_CreateReplicationJob_402656482(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReplicationJob_402656481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656483 = header.getOrDefault("X-Amz-Target")
  valid_402656483 = validateParameter(valid_402656483, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.CreateReplicationJob"))
  if valid_402656483 != nil:
    section.add "X-Amz-Target", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Security-Token", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Signature")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Signature", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Algorithm", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Date")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Date", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Credential")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Credential", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656490
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

proc call*(call_402656492: Call_CreateReplicationJob_402656480;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
                                                                                         ## 
  let valid = call_402656492.validator(path, query, header, formData, body, _)
  let scheme = call_402656492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656492.makeUrl(scheme.get, call_402656492.host, call_402656492.base,
                                   call_402656492.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656492, uri, valid, _)

proc call*(call_402656493: Call_CreateReplicationJob_402656480; body: JsonNode): Recallable =
  ## createReplicationJob
  ## Creates a replication job. The replication job schedules periodic replication runs to replicate your server to AWS. Each replication run creates an Amazon Machine Image (AMI).
  ##   
                                                                                                                                                                                    ## body: JObject (required)
  var body_402656494 = newJObject()
  if body != nil:
    body_402656494 = body
  result = call_402656493.call(nil, nil, nil, nil, body_402656494)

var createReplicationJob* = Call_CreateReplicationJob_402656480(
    name: "createReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.CreateReplicationJob",
    validator: validate_CreateReplicationJob_402656481, base: "/",
    makeUrl: url_CreateReplicationJob_402656482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_402656495 = ref object of OpenApiRestCall_402656035
proc url_DeleteApp_402656497(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_402656496(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656498 = header.getOrDefault("X-Amz-Target")
  valid_402656498 = validateParameter(valid_402656498, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteApp"))
  if valid_402656498 != nil:
    section.add "X-Amz-Target", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Security-Token", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Signature")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Signature", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Algorithm", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Date")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Date", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Credential")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Credential", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656505
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

proc call*(call_402656507: Call_DeleteApp_402656495; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_DeleteApp_402656495; body: JsonNode): Recallable =
  ## deleteApp
  ## Deletes an existing application. Optionally deletes the launched stack associated with the application and all AWS SMS replication jobs for servers in the application.
  ##   
                                                                                                                                                                            ## body: JObject (required)
  var body_402656509 = newJObject()
  if body != nil:
    body_402656509 = body
  result = call_402656508.call(nil, nil, nil, nil, body_402656509)

var deleteApp* = Call_DeleteApp_402656495(name: "deleteApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteApp",
    validator: validate_DeleteApp_402656496, base: "/", makeUrl: url_DeleteApp_402656497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppLaunchConfiguration_402656510 = ref object of OpenApiRestCall_402656035
proc url_DeleteAppLaunchConfiguration_402656512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppLaunchConfiguration_402656511(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656513 = header.getOrDefault("X-Amz-Target")
  valid_402656513 = validateParameter(valid_402656513, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration"))
  if valid_402656513 != nil:
    section.add "X-Amz-Target", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Security-Token", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Signature")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Signature", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Algorithm", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Date")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Date", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Credential")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Credential", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656520
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

proc call*(call_402656522: Call_DeleteAppLaunchConfiguration_402656510;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes existing launch configuration for an application.
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_DeleteAppLaunchConfiguration_402656510;
           body: JsonNode): Recallable =
  ## deleteAppLaunchConfiguration
  ## Deletes existing launch configuration for an application.
  ##   body: JObject (required)
  var body_402656524 = newJObject()
  if body != nil:
    body_402656524 = body
  result = call_402656523.call(nil, nil, nil, nil, body_402656524)

var deleteAppLaunchConfiguration* = Call_DeleteAppLaunchConfiguration_402656510(
    name: "deleteAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppLaunchConfiguration",
    validator: validate_DeleteAppLaunchConfiguration_402656511, base: "/",
    makeUrl: url_DeleteAppLaunchConfiguration_402656512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAppReplicationConfiguration_402656525 = ref object of OpenApiRestCall_402656035
proc url_DeleteAppReplicationConfiguration_402656527(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAppReplicationConfiguration_402656526(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656528 = header.getOrDefault("X-Amz-Target")
  valid_402656528 = validateParameter(valid_402656528, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration"))
  if valid_402656528 != nil:
    section.add "X-Amz-Target", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Security-Token", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Signature")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Signature", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Algorithm", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Date")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Date", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Credential")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Credential", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656535
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

proc call*(call_402656537: Call_DeleteAppReplicationConfiguration_402656525;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes existing replication configuration for an application.
                                                                                         ## 
  let valid = call_402656537.validator(path, query, header, formData, body, _)
  let scheme = call_402656537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656537.makeUrl(scheme.get, call_402656537.host, call_402656537.base,
                                   call_402656537.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656537, uri, valid, _)

proc call*(call_402656538: Call_DeleteAppReplicationConfiguration_402656525;
           body: JsonNode): Recallable =
  ## deleteAppReplicationConfiguration
  ## Deletes existing replication configuration for an application.
  ##   body: JObject (required)
  var body_402656539 = newJObject()
  if body != nil:
    body_402656539 = body
  result = call_402656538.call(nil, nil, nil, nil, body_402656539)

var deleteAppReplicationConfiguration* = Call_DeleteAppReplicationConfiguration_402656525(
    name: "deleteAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteAppReplicationConfiguration",
    validator: validate_DeleteAppReplicationConfiguration_402656526, base: "/",
    makeUrl: url_DeleteAppReplicationConfiguration_402656527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationJob_402656540 = ref object of OpenApiRestCall_402656035
proc url_DeleteReplicationJob_402656542(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReplicationJob_402656541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656543 = header.getOrDefault("X-Amz-Target")
  valid_402656543 = validateParameter(valid_402656543, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteReplicationJob"))
  if valid_402656543 != nil:
    section.add "X-Amz-Target", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Security-Token", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Signature")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Signature", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Algorithm", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Date")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Date", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Credential")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Credential", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656550
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

proc call*(call_402656552: Call_DeleteReplicationJob_402656540;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
                                                                                         ## 
  let valid = call_402656552.validator(path, query, header, formData, body, _)
  let scheme = call_402656552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656552.makeUrl(scheme.get, call_402656552.host, call_402656552.base,
                                   call_402656552.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656552, uri, valid, _)

proc call*(call_402656553: Call_DeleteReplicationJob_402656540; body: JsonNode): Recallable =
  ## deleteReplicationJob
  ## <p>Deletes the specified replication job.</p> <p>After you delete a replication job, there are no further replication runs. AWS deletes the contents of the Amazon S3 bucket used to store AWS SMS artifacts. The AMIs created by the replication runs are not deleted.</p>
  ##   
                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656554 = newJObject()
  if body != nil:
    body_402656554 = body
  result = call_402656553.call(nil, nil, nil, nil, body_402656554)

var deleteReplicationJob* = Call_DeleteReplicationJob_402656540(
    name: "deleteReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteReplicationJob",
    validator: validate_DeleteReplicationJob_402656541, base: "/",
    makeUrl: url_DeleteReplicationJob_402656542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServerCatalog_402656555 = ref object of OpenApiRestCall_402656035
proc url_DeleteServerCatalog_402656557(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteServerCatalog_402656556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656558 = header.getOrDefault("X-Amz-Target")
  valid_402656558 = validateParameter(valid_402656558, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DeleteServerCatalog"))
  if valid_402656558 != nil:
    section.add "X-Amz-Target", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Security-Token", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Signature")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Signature", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Algorithm", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Date")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Date", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Credential")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Credential", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656565
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

proc call*(call_402656567: Call_DeleteServerCatalog_402656555;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes all servers from your server catalog.
                                                                                         ## 
  let valid = call_402656567.validator(path, query, header, formData, body, _)
  let scheme = call_402656567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656567.makeUrl(scheme.get, call_402656567.host, call_402656567.base,
                                   call_402656567.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656567, uri, valid, _)

proc call*(call_402656568: Call_DeleteServerCatalog_402656555; body: JsonNode): Recallable =
  ## deleteServerCatalog
  ## Deletes all servers from your server catalog.
  ##   body: JObject (required)
  var body_402656569 = newJObject()
  if body != nil:
    body_402656569 = body
  result = call_402656568.call(nil, nil, nil, nil, body_402656569)

var deleteServerCatalog* = Call_DeleteServerCatalog_402656555(
    name: "deleteServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DeleteServerCatalog",
    validator: validate_DeleteServerCatalog_402656556, base: "/",
    makeUrl: url_DeleteServerCatalog_402656557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConnector_402656570 = ref object of OpenApiRestCall_402656035
proc url_DisassociateConnector_402656572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConnector_402656571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656573 = header.getOrDefault("X-Amz-Target")
  valid_402656573 = validateParameter(valid_402656573, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.DisassociateConnector"))
  if valid_402656573 != nil:
    section.add "X-Amz-Target", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Security-Token", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Signature")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Signature", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Algorithm", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Date")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Date", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Credential")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Credential", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656580
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

proc call*(call_402656582: Call_DisassociateConnector_402656570;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
                                                                                         ## 
  let valid = call_402656582.validator(path, query, header, formData, body, _)
  let scheme = call_402656582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656582.makeUrl(scheme.get, call_402656582.host, call_402656582.base,
                                   call_402656582.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656582, uri, valid, _)

proc call*(call_402656583: Call_DisassociateConnector_402656570; body: JsonNode): Recallable =
  ## disassociateConnector
  ## <p>Disassociates the specified connector from AWS SMS.</p> <p>After you disassociate a connector, it is no longer available to support replication jobs.</p>
  ##   
                                                                                                                                                                 ## body: JObject (required)
  var body_402656584 = newJObject()
  if body != nil:
    body_402656584 = body
  result = call_402656583.call(nil, nil, nil, nil, body_402656584)

var disassociateConnector* = Call_DisassociateConnector_402656570(
    name: "disassociateConnector", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.DisassociateConnector",
    validator: validate_DisassociateConnector_402656571, base: "/",
    makeUrl: url_DisassociateConnector_402656572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateChangeSet_402656585 = ref object of OpenApiRestCall_402656035
proc url_GenerateChangeSet_402656587(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateChangeSet_402656586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656588 = header.getOrDefault("X-Amz-Target")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateChangeSet"))
  if valid_402656588 != nil:
    section.add "X-Amz-Target", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Security-Token", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Signature")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Signature", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Algorithm", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Date")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Date", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Credential")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Credential", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656595
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

proc call*(call_402656597: Call_GenerateChangeSet_402656585;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
                                                                                         ## 
  let valid = call_402656597.validator(path, query, header, formData, body, _)
  let scheme = call_402656597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656597.makeUrl(scheme.get, call_402656597.host, call_402656597.base,
                                   call_402656597.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656597, uri, valid, _)

proc call*(call_402656598: Call_GenerateChangeSet_402656585; body: JsonNode): Recallable =
  ## generateChangeSet
  ## Generates a target change set for a currently launched stack and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   
                                                                                                                                            ## body: JObject (required)
  var body_402656599 = newJObject()
  if body != nil:
    body_402656599 = body
  result = call_402656598.call(nil, nil, nil, nil, body_402656599)

var generateChangeSet* = Call_GenerateChangeSet_402656585(
    name: "generateChangeSet", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateChangeSet",
    validator: validate_GenerateChangeSet_402656586, base: "/",
    makeUrl: url_GenerateChangeSet_402656587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GenerateTemplate_402656600 = ref object of OpenApiRestCall_402656035
proc url_GenerateTemplate_402656602(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GenerateTemplate_402656601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656603 = header.getOrDefault("X-Amz-Target")
  valid_402656603 = validateParameter(valid_402656603, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GenerateTemplate"))
  if valid_402656603 != nil:
    section.add "X-Amz-Target", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Security-Token", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Signature")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Signature", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Algorithm", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Date")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Date", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Credential")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Credential", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656610
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

proc call*(call_402656612: Call_GenerateTemplate_402656600;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
                                                                                         ## 
  let valid = call_402656612.validator(path, query, header, formData, body, _)
  let scheme = call_402656612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656612.makeUrl(scheme.get, call_402656612.host, call_402656612.base,
                                   call_402656612.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656612, uri, valid, _)

proc call*(call_402656613: Call_GenerateTemplate_402656600; body: JsonNode): Recallable =
  ## generateTemplate
  ## Generates an Amazon CloudFormation template based on the current launch configuration and writes it to an Amazon S3 object in the customer’s Amazon S3 bucket.
  ##   
                                                                                                                                                                     ## body: JObject (required)
  var body_402656614 = newJObject()
  if body != nil:
    body_402656614 = body
  result = call_402656613.call(nil, nil, nil, nil, body_402656614)

var generateTemplate* = Call_GenerateTemplate_402656600(
    name: "generateTemplate", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GenerateTemplate",
    validator: validate_GenerateTemplate_402656601, base: "/",
    makeUrl: url_GenerateTemplate_402656602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApp_402656615 = ref object of OpenApiRestCall_402656035
proc url_GetApp_402656617(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApp_402656616(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656618 = header.getOrDefault("X-Amz-Target")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetApp"))
  if valid_402656618 != nil:
    section.add "X-Amz-Target", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Security-Token", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Signature")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Signature", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Algorithm", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Date")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Date", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Credential")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Credential", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656625
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

proc call*(call_402656627: Call_GetApp_402656615; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve information about an application.
                                                                                         ## 
  let valid = call_402656627.validator(path, query, header, formData, body, _)
  let scheme = call_402656627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656627.makeUrl(scheme.get, call_402656627.host, call_402656627.base,
                                   call_402656627.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656627, uri, valid, _)

proc call*(call_402656628: Call_GetApp_402656615; body: JsonNode): Recallable =
  ## getApp
  ## Retrieve information about an application.
  ##   body: JObject (required)
  var body_402656629 = newJObject()
  if body != nil:
    body_402656629 = body
  result = call_402656628.call(nil, nil, nil, nil, body_402656629)

var getApp* = Call_GetApp_402656615(name: "getApp", meth: HttpMethod.HttpPost,
                                    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetApp",
                                    validator: validate_GetApp_402656616,
                                    base: "/", makeUrl: url_GetApp_402656617,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppLaunchConfiguration_402656630 = ref object of OpenApiRestCall_402656035
proc url_GetAppLaunchConfiguration_402656632(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppLaunchConfiguration_402656631(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656633 = header.getOrDefault("X-Amz-Target")
  valid_402656633 = validateParameter(valid_402656633, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration"))
  if valid_402656633 != nil:
    section.add "X-Amz-Target", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Security-Token", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Signature")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Signature", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Algorithm", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Date")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Date", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Credential")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Credential", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656640
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

proc call*(call_402656642: Call_GetAppLaunchConfiguration_402656630;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the application launch configuration associated with an application.
                                                                                         ## 
  let valid = call_402656642.validator(path, query, header, formData, body, _)
  let scheme = call_402656642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656642.makeUrl(scheme.get, call_402656642.host, call_402656642.base,
                                   call_402656642.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656642, uri, valid, _)

proc call*(call_402656643: Call_GetAppLaunchConfiguration_402656630;
           body: JsonNode): Recallable =
  ## getAppLaunchConfiguration
  ## Retrieves the application launch configuration associated with an application.
  ##   
                                                                                   ## body: JObject (required)
  var body_402656644 = newJObject()
  if body != nil:
    body_402656644 = body
  result = call_402656643.call(nil, nil, nil, nil, body_402656644)

var getAppLaunchConfiguration* = Call_GetAppLaunchConfiguration_402656630(
    name: "getAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppLaunchConfiguration",
    validator: validate_GetAppLaunchConfiguration_402656631, base: "/",
    makeUrl: url_GetAppLaunchConfiguration_402656632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAppReplicationConfiguration_402656645 = ref object of OpenApiRestCall_402656035
proc url_GetAppReplicationConfiguration_402656647(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAppReplicationConfiguration_402656646(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656648 = header.getOrDefault("X-Amz-Target")
  valid_402656648 = validateParameter(valid_402656648, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration"))
  if valid_402656648 != nil:
    section.add "X-Amz-Target", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Security-Token", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Signature")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Signature", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Algorithm", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Date")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Date", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Credential")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Credential", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656655
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

proc call*(call_402656657: Call_GetAppReplicationConfiguration_402656645;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves an application replication configuration associatd with an application.
                                                                                         ## 
  let valid = call_402656657.validator(path, query, header, formData, body, _)
  let scheme = call_402656657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656657.makeUrl(scheme.get, call_402656657.host, call_402656657.base,
                                   call_402656657.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656657, uri, valid, _)

proc call*(call_402656658: Call_GetAppReplicationConfiguration_402656645;
           body: JsonNode): Recallable =
  ## getAppReplicationConfiguration
  ## Retrieves an application replication configuration associatd with an application.
  ##   
                                                                                      ## body: JObject (required)
  var body_402656659 = newJObject()
  if body != nil:
    body_402656659 = body
  result = call_402656658.call(nil, nil, nil, nil, body_402656659)

var getAppReplicationConfiguration* = Call_GetAppReplicationConfiguration_402656645(
    name: "getAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetAppReplicationConfiguration",
    validator: validate_GetAppReplicationConfiguration_402656646, base: "/",
    makeUrl: url_GetAppReplicationConfiguration_402656647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectors_402656660 = ref object of OpenApiRestCall_402656035
proc url_GetConnectors_402656662(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnectors_402656661(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656663 = query.getOrDefault("maxResults")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "maxResults", valid_402656663
  var valid_402656664 = query.getOrDefault("nextToken")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "nextToken", valid_402656664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656665 = header.getOrDefault("X-Amz-Target")
  valid_402656665 = validateParameter(valid_402656665, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetConnectors"))
  if valid_402656665 != nil:
    section.add "X-Amz-Target", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Security-Token", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Signature")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Signature", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Algorithm", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Date")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Date", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Credential")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Credential", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656672
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

proc call*(call_402656674: Call_GetConnectors_402656660; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the connectors registered with the AWS SMS.
                                                                                         ## 
  let valid = call_402656674.validator(path, query, header, formData, body, _)
  let scheme = call_402656674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656674.makeUrl(scheme.get, call_402656674.host, call_402656674.base,
                                   call_402656674.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656674, uri, valid, _)

proc call*(call_402656675: Call_GetConnectors_402656660; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getConnectors
  ## Describes the connectors registered with the AWS SMS.
  ##   maxResults: string
                                                          ##             : Pagination limit
  ##   
                                                                                           ## nextToken: string
                                                                                           ##            
                                                                                           ## : 
                                                                                           ## Pagination 
                                                                                           ## token
  ##   
                                                                                                   ## body: JObject (required)
  var query_402656676 = newJObject()
  var body_402656677 = newJObject()
  add(query_402656676, "maxResults", newJString(maxResults))
  add(query_402656676, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656677 = body
  result = call_402656675.call(nil, query_402656676, nil, nil, body_402656677)

var getConnectors* = Call_GetConnectors_402656660(name: "getConnectors",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetConnectors",
    validator: validate_GetConnectors_402656661, base: "/",
    makeUrl: url_GetConnectors_402656662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationJobs_402656678 = ref object of OpenApiRestCall_402656035
proc url_GetReplicationJobs_402656680(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReplicationJobs_402656679(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656681 = query.getOrDefault("maxResults")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "maxResults", valid_402656681
  var valid_402656682 = query.getOrDefault("nextToken")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "nextToken", valid_402656682
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656683 = header.getOrDefault("X-Amz-Target")
  valid_402656683 = validateParameter(valid_402656683, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationJobs"))
  if valid_402656683 != nil:
    section.add "X-Amz-Target", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Security-Token", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Signature")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Signature", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Algorithm", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Date")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Date", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Credential")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Credential", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656690
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

proc call*(call_402656692: Call_GetReplicationJobs_402656678;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified replication job or all of your replication jobs.
                                                                                         ## 
  let valid = call_402656692.validator(path, query, header, formData, body, _)
  let scheme = call_402656692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656692.makeUrl(scheme.get, call_402656692.host, call_402656692.base,
                                   call_402656692.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656692, uri, valid, _)

proc call*(call_402656693: Call_GetReplicationJobs_402656678; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationJobs
  ## Describes the specified replication job or all of your replication jobs.
  ##   
                                                                             ## maxResults: string
                                                                             ##             
                                                                             ## : 
                                                                             ## Pagination 
                                                                             ## limit
  ##   
                                                                                     ## nextToken: string
                                                                                     ##            
                                                                                     ## : 
                                                                                     ## Pagination 
                                                                                     ## token
  ##   
                                                                                             ## body: JObject (required)
  var query_402656694 = newJObject()
  var body_402656695 = newJObject()
  add(query_402656694, "maxResults", newJString(maxResults))
  add(query_402656694, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656695 = body
  result = call_402656693.call(nil, query_402656694, nil, nil, body_402656695)

var getReplicationJobs* = Call_GetReplicationJobs_402656678(
    name: "getReplicationJobs", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationJobs",
    validator: validate_GetReplicationJobs_402656679, base: "/",
    makeUrl: url_GetReplicationJobs_402656680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReplicationRuns_402656696 = ref object of OpenApiRestCall_402656035
proc url_GetReplicationRuns_402656698(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetReplicationRuns_402656697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656699 = query.getOrDefault("maxResults")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "maxResults", valid_402656699
  var valid_402656700 = query.getOrDefault("nextToken")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "nextToken", valid_402656700
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656701 = header.getOrDefault("X-Amz-Target")
  valid_402656701 = validateParameter(valid_402656701, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetReplicationRuns"))
  if valid_402656701 != nil:
    section.add "X-Amz-Target", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Security-Token", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Signature")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Signature", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Algorithm", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Date")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Date", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Credential")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Credential", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656708
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

proc call*(call_402656710: Call_GetReplicationRuns_402656696;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the replication runs for the specified replication job.
                                                                                         ## 
  let valid = call_402656710.validator(path, query, header, formData, body, _)
  let scheme = call_402656710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656710.makeUrl(scheme.get, call_402656710.host, call_402656710.base,
                                   call_402656710.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656710, uri, valid, _)

proc call*(call_402656711: Call_GetReplicationRuns_402656696; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getReplicationRuns
  ## Describes the replication runs for the specified replication job.
  ##   
                                                                      ## maxResults: string
                                                                      ##             
                                                                      ## : 
                                                                      ## Pagination limit
  ##   
                                                                                         ## nextToken: string
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## Pagination 
                                                                                         ## token
  ##   
                                                                                                 ## body: JObject (required)
  var query_402656712 = newJObject()
  var body_402656713 = newJObject()
  add(query_402656712, "maxResults", newJString(maxResults))
  add(query_402656712, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656713 = body
  result = call_402656711.call(nil, query_402656712, nil, nil, body_402656713)

var getReplicationRuns* = Call_GetReplicationRuns_402656696(
    name: "getReplicationRuns", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetReplicationRuns",
    validator: validate_GetReplicationRuns_402656697, base: "/",
    makeUrl: url_GetReplicationRuns_402656698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServers_402656714 = ref object of OpenApiRestCall_402656035
proc url_GetServers_402656716(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServers_402656715(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656717 = query.getOrDefault("maxResults")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "maxResults", valid_402656717
  var valid_402656718 = query.getOrDefault("nextToken")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "nextToken", valid_402656718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656719 = header.getOrDefault("X-Amz-Target")
  valid_402656719 = validateParameter(valid_402656719, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.GetServers"))
  if valid_402656719 != nil:
    section.add "X-Amz-Target", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Security-Token", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Signature")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Signature", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Algorithm", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Date")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Date", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Credential")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Credential", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656726
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

proc call*(call_402656728: Call_GetServers_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
                                                                                         ## 
  let valid = call_402656728.validator(path, query, header, formData, body, _)
  let scheme = call_402656728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656728.makeUrl(scheme.get, call_402656728.host, call_402656728.base,
                                   call_402656728.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656728, uri, valid, _)

proc call*(call_402656729: Call_GetServers_402656714; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getServers
  ## <p>Describes the servers in your server catalog.</p> <p>Before you can describe your servers, you must import them using <a>ImportServerCatalog</a>.</p>
  ##   
                                                                                                                                                             ## maxResults: string
                                                                                                                                                             ##             
                                                                                                                                                             ## : 
                                                                                                                                                             ## Pagination 
                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                     ## nextToken: string
                                                                                                                                                                     ##            
                                                                                                                                                                     ## : 
                                                                                                                                                                     ## Pagination 
                                                                                                                                                                     ## token
  ##   
                                                                                                                                                                             ## body: JObject (required)
  var query_402656730 = newJObject()
  var body_402656731 = newJObject()
  add(query_402656730, "maxResults", newJString(maxResults))
  add(query_402656730, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656731 = body
  result = call_402656729.call(nil, query_402656730, nil, nil, body_402656731)

var getServers* = Call_GetServers_402656714(name: "getServers",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.GetServers",
    validator: validate_GetServers_402656715, base: "/",
    makeUrl: url_GetServers_402656716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportServerCatalog_402656732 = ref object of OpenApiRestCall_402656035
proc url_ImportServerCatalog_402656734(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportServerCatalog_402656733(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656735 = header.getOrDefault("X-Amz-Target")
  valid_402656735 = validateParameter(valid_402656735, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ImportServerCatalog"))
  if valid_402656735 != nil:
    section.add "X-Amz-Target", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Security-Token", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Signature")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Signature", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Algorithm", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Date")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Date", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Credential")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Credential", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656742
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

proc call*(call_402656744: Call_ImportServerCatalog_402656732;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
                                                                                         ## 
  let valid = call_402656744.validator(path, query, header, formData, body, _)
  let scheme = call_402656744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656744.makeUrl(scheme.get, call_402656744.host, call_402656744.base,
                                   call_402656744.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656744, uri, valid, _)

proc call*(call_402656745: Call_ImportServerCatalog_402656732; body: JsonNode): Recallable =
  ## importServerCatalog
  ## <p>Gathers a complete list of on-premises servers. Connectors must be installed and monitoring all servers that you want to import.</p> <p>This call returns immediately, but might take additional time to retrieve all the servers.</p>
  ##   
                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656746 = newJObject()
  if body != nil:
    body_402656746 = body
  result = call_402656745.call(nil, nil, nil, nil, body_402656746)

var importServerCatalog* = Call_ImportServerCatalog_402656732(
    name: "importServerCatalog", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ImportServerCatalog",
    validator: validate_ImportServerCatalog_402656733, base: "/",
    makeUrl: url_ImportServerCatalog_402656734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LaunchApp_402656747 = ref object of OpenApiRestCall_402656035
proc url_LaunchApp_402656749(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LaunchApp_402656748(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656750 = header.getOrDefault("X-Amz-Target")
  valid_402656750 = validateParameter(valid_402656750, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.LaunchApp"))
  if valid_402656750 != nil:
    section.add "X-Amz-Target", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Security-Token", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Signature")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Signature", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Algorithm", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Date")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Date", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Credential")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Credential", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656757
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

proc call*(call_402656759: Call_LaunchApp_402656747; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Launches an application stack.
                                                                                         ## 
  let valid = call_402656759.validator(path, query, header, formData, body, _)
  let scheme = call_402656759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656759.makeUrl(scheme.get, call_402656759.host, call_402656759.base,
                                   call_402656759.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656759, uri, valid, _)

proc call*(call_402656760: Call_LaunchApp_402656747; body: JsonNode): Recallable =
  ## launchApp
  ## Launches an application stack.
  ##   body: JObject (required)
  var body_402656761 = newJObject()
  if body != nil:
    body_402656761 = body
  result = call_402656760.call(nil, nil, nil, nil, body_402656761)

var launchApp* = Call_LaunchApp_402656747(name: "launchApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.LaunchApp",
    validator: validate_LaunchApp_402656748, base: "/", makeUrl: url_LaunchApp_402656749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_402656762 = ref object of OpenApiRestCall_402656035
proc url_ListApps_402656764(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_402656763(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656765 = header.getOrDefault("X-Amz-Target")
  valid_402656765 = validateParameter(valid_402656765, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.ListApps"))
  if valid_402656765 != nil:
    section.add "X-Amz-Target", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Security-Token", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Signature")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Signature", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Algorithm", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Date")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Date", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Credential")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Credential", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656772
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

proc call*(call_402656774: Call_ListApps_402656762; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of summaries for all applications.
                                                                                         ## 
  let valid = call_402656774.validator(path, query, header, formData, body, _)
  let scheme = call_402656774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656774.makeUrl(scheme.get, call_402656774.host, call_402656774.base,
                                   call_402656774.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656774, uri, valid, _)

proc call*(call_402656775: Call_ListApps_402656762; body: JsonNode): Recallable =
  ## listApps
  ## Returns a list of summaries for all applications.
  ##   body: JObject (required)
  var body_402656776 = newJObject()
  if body != nil:
    body_402656776 = body
  result = call_402656775.call(nil, nil, nil, nil, body_402656776)

var listApps* = Call_ListApps_402656762(name: "listApps",
                                        meth: HttpMethod.HttpPost,
                                        host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.ListApps",
                                        validator: validate_ListApps_402656763,
                                        base: "/", makeUrl: url_ListApps_402656764,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppLaunchConfiguration_402656777 = ref object of OpenApiRestCall_402656035
proc url_PutAppLaunchConfiguration_402656779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppLaunchConfiguration_402656778(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656780 = header.getOrDefault("X-Amz-Target")
  valid_402656780 = validateParameter(valid_402656780, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration"))
  if valid_402656780 != nil:
    section.add "X-Amz-Target", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Security-Token", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Signature")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Signature", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Algorithm", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Date")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Date", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Credential")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Credential", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656787
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

proc call*(call_402656789: Call_PutAppLaunchConfiguration_402656777;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a launch configuration for an application.
                                                                                         ## 
  let valid = call_402656789.validator(path, query, header, formData, body, _)
  let scheme = call_402656789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656789.makeUrl(scheme.get, call_402656789.host, call_402656789.base,
                                   call_402656789.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656789, uri, valid, _)

proc call*(call_402656790: Call_PutAppLaunchConfiguration_402656777;
           body: JsonNode): Recallable =
  ## putAppLaunchConfiguration
  ## Creates a launch configuration for an application.
  ##   body: JObject (required)
  var body_402656791 = newJObject()
  if body != nil:
    body_402656791 = body
  result = call_402656790.call(nil, nil, nil, nil, body_402656791)

var putAppLaunchConfiguration* = Call_PutAppLaunchConfiguration_402656777(
    name: "putAppLaunchConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppLaunchConfiguration",
    validator: validate_PutAppLaunchConfiguration_402656778, base: "/",
    makeUrl: url_PutAppLaunchConfiguration_402656779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAppReplicationConfiguration_402656792 = ref object of OpenApiRestCall_402656035
proc url_PutAppReplicationConfiguration_402656794(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAppReplicationConfiguration_402656793(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656795 = header.getOrDefault("X-Amz-Target")
  valid_402656795 = validateParameter(valid_402656795, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration"))
  if valid_402656795 != nil:
    section.add "X-Amz-Target", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Security-Token", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Signature")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Signature", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Algorithm", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Date")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Date", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Credential")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Credential", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656802
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

proc call*(call_402656804: Call_PutAppReplicationConfiguration_402656792;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates or updates a replication configuration for an application.
                                                                                         ## 
  let valid = call_402656804.validator(path, query, header, formData, body, _)
  let scheme = call_402656804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656804.makeUrl(scheme.get, call_402656804.host, call_402656804.base,
                                   call_402656804.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656804, uri, valid, _)

proc call*(call_402656805: Call_PutAppReplicationConfiguration_402656792;
           body: JsonNode): Recallable =
  ## putAppReplicationConfiguration
  ## Creates or updates a replication configuration for an application.
  ##   body: JObject 
                                                                       ## (required)
  var body_402656806 = newJObject()
  if body != nil:
    body_402656806 = body
  result = call_402656805.call(nil, nil, nil, nil, body_402656806)

var putAppReplicationConfiguration* = Call_PutAppReplicationConfiguration_402656792(
    name: "putAppReplicationConfiguration", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.PutAppReplicationConfiguration",
    validator: validate_PutAppReplicationConfiguration_402656793, base: "/",
    makeUrl: url_PutAppReplicationConfiguration_402656794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAppReplication_402656807 = ref object of OpenApiRestCall_402656035
proc url_StartAppReplication_402656809(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAppReplication_402656808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656810 = header.getOrDefault("X-Amz-Target")
  valid_402656810 = validateParameter(valid_402656810, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartAppReplication"))
  if valid_402656810 != nil:
    section.add "X-Amz-Target", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Security-Token", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Signature")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Signature", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Algorithm", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Date")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Date", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Credential")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Credential", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656817
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

proc call*(call_402656819: Call_StartAppReplication_402656807;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts replicating an application.
                                                                                         ## 
  let valid = call_402656819.validator(path, query, header, formData, body, _)
  let scheme = call_402656819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656819.makeUrl(scheme.get, call_402656819.host, call_402656819.base,
                                   call_402656819.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656819, uri, valid, _)

proc call*(call_402656820: Call_StartAppReplication_402656807; body: JsonNode): Recallable =
  ## startAppReplication
  ## Starts replicating an application.
  ##   body: JObject (required)
  var body_402656821 = newJObject()
  if body != nil:
    body_402656821 = body
  result = call_402656820.call(nil, nil, nil, nil, body_402656821)

var startAppReplication* = Call_StartAppReplication_402656807(
    name: "startAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartAppReplication",
    validator: validate_StartAppReplication_402656808, base: "/",
    makeUrl: url_StartAppReplication_402656809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartOnDemandReplicationRun_402656822 = ref object of OpenApiRestCall_402656035
proc url_StartOnDemandReplicationRun_402656824(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartOnDemandReplicationRun_402656823(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656825 = header.getOrDefault("X-Amz-Target")
  valid_402656825 = validateParameter(valid_402656825, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun"))
  if valid_402656825 != nil:
    section.add "X-Amz-Target", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Security-Token", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Signature")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Signature", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Algorithm", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Date")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Date", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Credential")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Credential", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656832
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

proc call*(call_402656834: Call_StartOnDemandReplicationRun_402656822;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
                                                                                         ## 
  let valid = call_402656834.validator(path, query, header, formData, body, _)
  let scheme = call_402656834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656834.makeUrl(scheme.get, call_402656834.host, call_402656834.base,
                                   call_402656834.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656834, uri, valid, _)

proc call*(call_402656835: Call_StartOnDemandReplicationRun_402656822;
           body: JsonNode): Recallable =
  ## startOnDemandReplicationRun
  ## <p>Starts an on-demand replication run for the specified replication job. This replication run starts immediately. This replication run is in addition to the ones already scheduled.</p> <p>There is a limit on the number of on-demand replications runs you can request in a 24-hour period.</p>
  ##   
                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656836 = newJObject()
  if body != nil:
    body_402656836 = body
  result = call_402656835.call(nil, nil, nil, nil, body_402656836)

var startOnDemandReplicationRun* = Call_StartOnDemandReplicationRun_402656822(
    name: "startOnDemandReplicationRun", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StartOnDemandReplicationRun",
    validator: validate_StartOnDemandReplicationRun_402656823, base: "/",
    makeUrl: url_StartOnDemandReplicationRun_402656824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAppReplication_402656837 = ref object of OpenApiRestCall_402656035
proc url_StopAppReplication_402656839(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAppReplication_402656838(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656840 = header.getOrDefault("X-Amz-Target")
  valid_402656840 = validateParameter(valid_402656840, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.StopAppReplication"))
  if valid_402656840 != nil:
    section.add "X-Amz-Target", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Security-Token", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Signature")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Signature", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Algorithm", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Date")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Date", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Credential")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Credential", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656847
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

proc call*(call_402656849: Call_StopAppReplication_402656837;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops replicating an application.
                                                                                         ## 
  let valid = call_402656849.validator(path, query, header, formData, body, _)
  let scheme = call_402656849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656849.makeUrl(scheme.get, call_402656849.host, call_402656849.base,
                                   call_402656849.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656849, uri, valid, _)

proc call*(call_402656850: Call_StopAppReplication_402656837; body: JsonNode): Recallable =
  ## stopAppReplication
  ## Stops replicating an application.
  ##   body: JObject (required)
  var body_402656851 = newJObject()
  if body != nil:
    body_402656851 = body
  result = call_402656850.call(nil, nil, nil, nil, body_402656851)

var stopAppReplication* = Call_StopAppReplication_402656837(
    name: "stopAppReplication", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.StopAppReplication",
    validator: validate_StopAppReplication_402656838, base: "/",
    makeUrl: url_StopAppReplication_402656839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateApp_402656852 = ref object of OpenApiRestCall_402656035
proc url_TerminateApp_402656854(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateApp_402656853(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656855 = header.getOrDefault("X-Amz-Target")
  valid_402656855 = validateParameter(valid_402656855, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.TerminateApp"))
  if valid_402656855 != nil:
    section.add "X-Amz-Target", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Security-Token", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Signature")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Signature", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Algorithm", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Date")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Date", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Credential")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Credential", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656862
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

proc call*(call_402656864: Call_TerminateApp_402656852; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Terminates the stack for an application.
                                                                                         ## 
  let valid = call_402656864.validator(path, query, header, formData, body, _)
  let scheme = call_402656864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656864.makeUrl(scheme.get, call_402656864.host, call_402656864.base,
                                   call_402656864.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656864, uri, valid, _)

proc call*(call_402656865: Call_TerminateApp_402656852; body: JsonNode): Recallable =
  ## terminateApp
  ## Terminates the stack for an application.
  ##   body: JObject (required)
  var body_402656866 = newJObject()
  if body != nil:
    body_402656866 = body
  result = call_402656865.call(nil, nil, nil, nil, body_402656866)

var terminateApp* = Call_TerminateApp_402656852(name: "terminateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.TerminateApp",
    validator: validate_TerminateApp_402656853, base: "/",
    makeUrl: url_TerminateApp_402656854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApp_402656867 = ref object of OpenApiRestCall_402656035
proc url_UpdateApp_402656869(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApp_402656868(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656870 = header.getOrDefault("X-Amz-Target")
  valid_402656870 = validateParameter(valid_402656870, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateApp"))
  if valid_402656870 != nil:
    section.add "X-Amz-Target", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Security-Token", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Signature")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Signature", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Algorithm", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Date")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Date", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Credential")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Credential", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656877
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

proc call*(call_402656879: Call_UpdateApp_402656867; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an application.
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_UpdateApp_402656867; body: JsonNode): Recallable =
  ## updateApp
  ## Updates an application.
  ##   body: JObject (required)
  var body_402656881 = newJObject()
  if body != nil:
    body_402656881 = body
  result = call_402656880.call(nil, nil, nil, nil, body_402656881)

var updateApp* = Call_UpdateApp_402656867(name: "updateApp",
    meth: HttpMethod.HttpPost, host: "sms.amazonaws.com",
    route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateApp",
    validator: validate_UpdateApp_402656868, base: "/", makeUrl: url_UpdateApp_402656869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReplicationJob_402656882 = ref object of OpenApiRestCall_402656035
proc url_UpdateReplicationJob_402656884(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateReplicationJob_402656883(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656885 = header.getOrDefault("X-Amz-Target")
  valid_402656885 = validateParameter(valid_402656885, JString, required = true, default = newJString(
      "AWSServerMigrationService_V2016_10_24.UpdateReplicationJob"))
  if valid_402656885 != nil:
    section.add "X-Amz-Target", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Security-Token", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Signature")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Signature", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Algorithm", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Date")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Date", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Credential")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Credential", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656892
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

proc call*(call_402656894: Call_UpdateReplicationJob_402656882;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified settings for the specified replication job.
                                                                                         ## 
  let valid = call_402656894.validator(path, query, header, formData, body, _)
  let scheme = call_402656894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656894.makeUrl(scheme.get, call_402656894.host, call_402656894.base,
                                   call_402656894.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656894, uri, valid, _)

proc call*(call_402656895: Call_UpdateReplicationJob_402656882; body: JsonNode): Recallable =
  ## updateReplicationJob
  ## Updates the specified settings for the specified replication job.
  ##   body: JObject (required)
  var body_402656896 = newJObject()
  if body != nil:
    body_402656896 = body
  result = call_402656895.call(nil, nil, nil, nil, body_402656896)

var updateReplicationJob* = Call_UpdateReplicationJob_402656882(
    name: "updateReplicationJob", meth: HttpMethod.HttpPost,
    host: "sms.amazonaws.com", route: "/#X-Amz-Target=AWSServerMigrationService_V2016_10_24.UpdateReplicationJob",
    validator: validate_UpdateReplicationJob_402656883, base: "/",
    makeUrl: url_UpdateReplicationJob_402656884,
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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