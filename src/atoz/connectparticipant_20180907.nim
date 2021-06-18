
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Connect Participant Service
## version: 2018-09-07
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Connect is a cloud-based contact center solution that makes it easy to set up and manage a customer contact center and provide reliable customer engagement at any scale.</p> <p>Amazon Connect enables customer contacts through voice or chat.</p> <p>The APIs described here are used by chat participants, such as agents and customers.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/connect/
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "participant.connect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "participant.connect.ap-southeast-1.amazonaws.com", "us-west-2": "participant.connect.us-west-2.amazonaws.com", "eu-west-2": "participant.connect.eu-west-2.amazonaws.com", "ap-northeast-3": "participant.connect.ap-northeast-3.amazonaws.com", "eu-central-1": "participant.connect.eu-central-1.amazonaws.com", "us-east-2": "participant.connect.us-east-2.amazonaws.com", "us-east-1": "participant.connect.us-east-1.amazonaws.com", "cn-northwest-1": "participant.connect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "participant.connect.ap-south-1.amazonaws.com", "eu-north-1": "participant.connect.eu-north-1.amazonaws.com", "ap-northeast-2": "participant.connect.ap-northeast-2.amazonaws.com", "us-west-1": "participant.connect.us-west-1.amazonaws.com", "us-gov-east-1": "participant.connect.us-gov-east-1.amazonaws.com", "eu-west-3": "participant.connect.eu-west-3.amazonaws.com", "cn-north-1": "participant.connect.cn-north-1.amazonaws.com.cn", "sa-east-1": "participant.connect.sa-east-1.amazonaws.com", "eu-west-1": "participant.connect.eu-west-1.amazonaws.com", "us-gov-west-1": "participant.connect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "participant.connect.ap-southeast-2.amazonaws.com", "ca-central-1": "participant.connect.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "participant.connect.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "participant.connect.ap-southeast-1.amazonaws.com",
      "us-west-2": "participant.connect.us-west-2.amazonaws.com",
      "eu-west-2": "participant.connect.eu-west-2.amazonaws.com",
      "ap-northeast-3": "participant.connect.ap-northeast-3.amazonaws.com",
      "eu-central-1": "participant.connect.eu-central-1.amazonaws.com",
      "us-east-2": "participant.connect.us-east-2.amazonaws.com",
      "us-east-1": "participant.connect.us-east-1.amazonaws.com",
      "cn-northwest-1": "participant.connect.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "participant.connect.ap-south-1.amazonaws.com",
      "eu-north-1": "participant.connect.eu-north-1.amazonaws.com",
      "ap-northeast-2": "participant.connect.ap-northeast-2.amazonaws.com",
      "us-west-1": "participant.connect.us-west-1.amazonaws.com",
      "us-gov-east-1": "participant.connect.us-gov-east-1.amazonaws.com",
      "eu-west-3": "participant.connect.eu-west-3.amazonaws.com",
      "cn-north-1": "participant.connect.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "participant.connect.sa-east-1.amazonaws.com",
      "eu-west-1": "participant.connect.eu-west-1.amazonaws.com",
      "us-gov-west-1": "participant.connect.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "participant.connect.ap-southeast-2.amazonaws.com",
      "ca-central-1": "participant.connect.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "connectparticipant"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateParticipantConnection_402656288 = ref object of OpenApiRestCall_402656038
proc url_CreateParticipantConnection_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateParticipantConnection_402656289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Bearer: JString (required)
                                ##               : Participant Token as obtained from <a 
                                ## href="https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContactResponse.html">StartChatContact</a> 
                                ## API 
                                ## response.
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656372 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Security-Token", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Signature")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Signature", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Algorithm", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Date")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Date", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Credential")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Credential", valid_402656377
  assert header != nil,
         "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_402656378 = header.getOrDefault("X-Amz-Bearer")
  valid_402656378 = validateParameter(valid_402656378, JString, required = true,
                                      default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Bearer", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656379
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

proc call*(call_402656394: Call_CreateParticipantConnection_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
                                                                                         ## 
  let valid = call_402656394.validator(path, query, header, formData, body, _)
  let scheme = call_402656394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656394.makeUrl(scheme.get, call_402656394.host, call_402656394.base,
                                   call_402656394.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656394, uri, valid, _)

proc call*(call_402656443: Call_CreateParticipantConnection_402656288;
           body: JsonNode): Recallable =
  ## createParticipantConnection
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656444 = newJObject()
  if body != nil:
    body_402656444 = body
  result = call_402656443.call(nil, nil, nil, nil, body_402656444)

var createParticipantConnection* = Call_CreateParticipantConnection_402656288(
    name: "createParticipantConnection", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/connection#X-Amz-Bearer",
    validator: validate_CreateParticipantConnection_402656289, base: "/",
    makeUrl: url_CreateParticipantConnection_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectParticipant_402656471 = ref object of OpenApiRestCall_402656038
proc url_DisconnectParticipant_402656473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisconnectParticipant_402656472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Bearer: JString (required)
                                ##               : The authentication token associated with the participant's connection.
  ##   
                                                                                                                         ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656474 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656474 = validateParameter(valid_402656474, JString,
                                      required = false, default = nil)
  if valid_402656474 != nil:
    section.add "X-Amz-Security-Token", valid_402656474
  var valid_402656475 = header.getOrDefault("X-Amz-Signature")
  valid_402656475 = validateParameter(valid_402656475, JString,
                                      required = false, default = nil)
  if valid_402656475 != nil:
    section.add "X-Amz-Signature", valid_402656475
  var valid_402656476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Algorithm", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Date")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Date", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Credential")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Credential", valid_402656479
  assert header != nil,
         "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_402656480 = header.getOrDefault("X-Amz-Bearer")
  valid_402656480 = validateParameter(valid_402656480, JString, required = true,
                                      default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Bearer", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656481
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

proc call*(call_402656483: Call_DisconnectParticipant_402656471;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
                                                                                         ## 
  let valid = call_402656483.validator(path, query, header, formData, body, _)
  let scheme = call_402656483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656483.makeUrl(scheme.get, call_402656483.host, call_402656483.base,
                                   call_402656483.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656483, uri, valid, _)

proc call*(call_402656484: Call_DisconnectParticipant_402656471; body: JsonNode): Recallable =
  ## disconnectParticipant
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   
                                                                                                                    ## body: JObject (required)
  var body_402656485 = newJObject()
  if body != nil:
    body_402656485 = body
  result = call_402656484.call(nil, nil, nil, nil, body_402656485)

var disconnectParticipant* = Call_DisconnectParticipant_402656471(
    name: "disconnectParticipant", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/disconnect#X-Amz-Bearer",
    validator: validate_DisconnectParticipant_402656472, base: "/",
    makeUrl: url_DisconnectParticipant_402656473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTranscript_402656486 = ref object of OpenApiRestCall_402656038
proc url_GetTranscript_402656488(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTranscript_402656487(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
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
  section = newJObject()
  var valid_402656489 = query.getOrDefault("MaxResults")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "MaxResults", valid_402656489
  var valid_402656490 = query.getOrDefault("NextToken")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "NextToken", valid_402656490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Bearer: JString (required)
                                ##               : The authentication token associated with the participant's connection.
  ##   
                                                                                                                         ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  assert header != nil,
         "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_402656497 = header.getOrDefault("X-Amz-Bearer")
  valid_402656497 = validateParameter(valid_402656497, JString, required = true,
                                      default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Bearer", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656498
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

proc call*(call_402656500: Call_GetTranscript_402656486; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
                                                                                         ## 
  let valid = call_402656500.validator(path, query, header, formData, body, _)
  let scheme = call_402656500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656500.makeUrl(scheme.get, call_402656500.host, call_402656500.base,
                                   call_402656500.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656500, uri, valid, _)

proc call*(call_402656501: Call_GetTranscript_402656486; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTranscript
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   
                                                                                                                                ## MaxResults: string
                                                                                                                                ##             
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## limit
  ##   
                                                                                                                                        ## body: JObject (required)
  ##   
                                                                                                                                                                   ## NextToken: string
                                                                                                                                                                   ##            
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## Pagination 
                                                                                                                                                                   ## token
  var query_402656502 = newJObject()
  var body_402656503 = newJObject()
  add(query_402656502, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656503 = body
  add(query_402656502, "NextToken", newJString(NextToken))
  result = call_402656501.call(nil, query_402656502, nil, nil, body_402656503)

var getTranscript* = Call_GetTranscript_402656486(name: "getTranscript",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/transcript#X-Amz-Bearer",
    validator: validate_GetTranscript_402656487, base: "/",
    makeUrl: url_GetTranscript_402656488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEvent_402656504 = ref object of OpenApiRestCall_402656038
proc url_SendEvent_402656506(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEvent_402656505(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Bearer: JString (required)
                                ##               : The authentication token associated with the participant's connection.
  ##   
                                                                                                                         ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Security-Token", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Signature")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Signature", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Algorithm", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Date")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Date", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Credential")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Credential", valid_402656512
  assert header != nil,
         "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_402656513 = header.getOrDefault("X-Amz-Bearer")
  valid_402656513 = validateParameter(valid_402656513, JString, required = true,
                                      default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Bearer", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
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

proc call*(call_402656516: Call_SendEvent_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_SendEvent_402656504; body: JsonNode): Recallable =
  ## sendEvent
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   
                                                                                                         ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var sendEvent* = Call_SendEvent_402656504(name: "sendEvent",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/event#X-Amz-Bearer", validator: validate_SendEvent_402656505,
    base: "/", makeUrl: url_SendEvent_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessage_402656519 = ref object of OpenApiRestCall_402656038
proc url_SendMessage_402656521(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendMessage_402656520(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Bearer: JString (required)
                                ##               : The authentication token associated with the connection.
  ##   
                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Security-Token", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Signature")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Signature", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Algorithm", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Date")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Date", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Credential")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Credential", valid_402656527
  assert header != nil,
         "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_402656528 = header.getOrDefault("X-Amz-Bearer")
  valid_402656528 = validateParameter(valid_402656528, JString, required = true,
                                      default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Bearer", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
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

proc call*(call_402656531: Call_SendMessage_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_SendMessage_402656519; body: JsonNode): Recallable =
  ## sendMessage
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   
                                                                                                          ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var sendMessage* = Call_SendMessage_402656519(name: "sendMessage",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/message#X-Amz-Bearer", validator: validate_SendMessage_402656520,
    base: "/", makeUrl: url_SendMessage_402656521,
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