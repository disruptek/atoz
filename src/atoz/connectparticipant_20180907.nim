
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "participant.connect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "participant.connect.ap-southeast-1.amazonaws.com", "us-west-2": "participant.connect.us-west-2.amazonaws.com", "eu-west-2": "participant.connect.eu-west-2.amazonaws.com", "ap-northeast-3": "participant.connect.ap-northeast-3.amazonaws.com", "eu-central-1": "participant.connect.eu-central-1.amazonaws.com", "us-east-2": "participant.connect.us-east-2.amazonaws.com", "us-east-1": "participant.connect.us-east-1.amazonaws.com", "cn-northwest-1": "participant.connect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "participant.connect.ap-south-1.amazonaws.com", "eu-north-1": "participant.connect.eu-north-1.amazonaws.com", "ap-northeast-2": "participant.connect.ap-northeast-2.amazonaws.com", "us-west-1": "participant.connect.us-west-1.amazonaws.com", "us-gov-east-1": "participant.connect.us-gov-east-1.amazonaws.com", "eu-west-3": "participant.connect.eu-west-3.amazonaws.com", "cn-north-1": "participant.connect.cn-north-1.amazonaws.com.cn", "sa-east-1": "participant.connect.sa-east-1.amazonaws.com", "eu-west-1": "participant.connect.eu-west-1.amazonaws.com", "us-gov-west-1": "participant.connect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "participant.connect.ap-southeast-2.amazonaws.com", "ca-central-1": "participant.connect.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateParticipantConnection_21625770 = ref object of OpenApiRestCall_21625426
proc url_CreateParticipantConnection_21625772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateParticipantConnection_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
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
  ##   X-Amz-Bearer: JString (required)
  ##               : Participant Token as obtained from <a 
  ## href="https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContactResponse.html">StartChatContact</a> API response.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625873 = header.getOrDefault("X-Amz-Date")
  valid_21625873 = validateParameter(valid_21625873, JString, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "X-Amz-Date", valid_21625873
  var valid_21625874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625874 = validateParameter(valid_21625874, JString, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "X-Amz-Security-Token", valid_21625874
  var valid_21625875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625875 = validateParameter(valid_21625875, JString, required = false,
                                   default = nil)
  if valid_21625875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625875
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_21625876 = header.getOrDefault("X-Amz-Bearer")
  valid_21625876 = validateParameter(valid_21625876, JString, required = true,
                                   default = nil)
  if valid_21625876 != nil:
    section.add "X-Amz-Bearer", valid_21625876
  var valid_21625877 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625877 = validateParameter(valid_21625877, JString, required = false,
                                   default = nil)
  if valid_21625877 != nil:
    section.add "X-Amz-Algorithm", valid_21625877
  var valid_21625878 = header.getOrDefault("X-Amz-Signature")
  valid_21625878 = validateParameter(valid_21625878, JString, required = false,
                                   default = nil)
  if valid_21625878 != nil:
    section.add "X-Amz-Signature", valid_21625878
  var valid_21625879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625879 = validateParameter(valid_21625879, JString, required = false,
                                   default = nil)
  if valid_21625879 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625879
  var valid_21625880 = header.getOrDefault("X-Amz-Credential")
  valid_21625880 = validateParameter(valid_21625880, JString, required = false,
                                   default = nil)
  if valid_21625880 != nil:
    section.add "X-Amz-Credential", valid_21625880
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

proc call*(call_21625906: Call_CreateParticipantConnection_21625770;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ## 
  let valid = call_21625906.validator(path, query, header, formData, body, _)
  let scheme = call_21625906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625906.makeUrl(scheme.get, call_21625906.host, call_21625906.base,
                               call_21625906.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625906, uri, valid, _)

proc call*(call_21625969: Call_CreateParticipantConnection_21625770; body: JsonNode): Recallable =
  ## createParticipantConnection
  ## <p>Creates the participant's connection. Note that ParticipantToken is used for invoking this API instead of ConnectionToken.</p> <p>The participant token is valid for the lifetime of the participant – until the they are part of a contact.</p> <p>The response URL for <code>WEBSOCKET</code> Type has a connect expiry timeout of 100s. Clients must manually connect to the returned websocket URL and subscribe to the desired topic. </p> <p>For chat, you need to publish the following on the established websocket connection:</p> <p> <code>{"topic":"aws/subscribe","content":{"topics":["aws/chat"]}}</code> </p> <p>Upon websocket URL expiry, as specified in the response ConnectionExpiry parameter, clients need to call this API again to obtain a new websocket URL and perform the same steps as before.</p>
  ##   body: JObject (required)
  var body_21625970 = newJObject()
  if body != nil:
    body_21625970 = body
  result = call_21625969.call(nil, nil, nil, nil, body_21625970)

var createParticipantConnection* = Call_CreateParticipantConnection_21625770(
    name: "createParticipantConnection", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/connection#X-Amz-Bearer",
    validator: validate_CreateParticipantConnection_21625771, base: "/",
    makeUrl: url_CreateParticipantConnection_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisconnectParticipant_21626006 = ref object of OpenApiRestCall_21625426
proc url_DisconnectParticipant_21626008(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisconnectParticipant_21626007(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626009 = header.getOrDefault("X-Amz-Date")
  valid_21626009 = validateParameter(valid_21626009, JString, required = false,
                                   default = nil)
  if valid_21626009 != nil:
    section.add "X-Amz-Date", valid_21626009
  var valid_21626010 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626010 = validateParameter(valid_21626010, JString, required = false,
                                   default = nil)
  if valid_21626010 != nil:
    section.add "X-Amz-Security-Token", valid_21626010
  var valid_21626011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626011 = validateParameter(valid_21626011, JString, required = false,
                                   default = nil)
  if valid_21626011 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626011
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_21626012 = header.getOrDefault("X-Amz-Bearer")
  valid_21626012 = validateParameter(valid_21626012, JString, required = true,
                                   default = nil)
  if valid_21626012 != nil:
    section.add "X-Amz-Bearer", valid_21626012
  var valid_21626013 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626013 = validateParameter(valid_21626013, JString, required = false,
                                   default = nil)
  if valid_21626013 != nil:
    section.add "X-Amz-Algorithm", valid_21626013
  var valid_21626014 = header.getOrDefault("X-Amz-Signature")
  valid_21626014 = validateParameter(valid_21626014, JString, required = false,
                                   default = nil)
  if valid_21626014 != nil:
    section.add "X-Amz-Signature", valid_21626014
  var valid_21626015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626015 = validateParameter(valid_21626015, JString, required = false,
                                   default = nil)
  if valid_21626015 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626015
  var valid_21626016 = header.getOrDefault("X-Amz-Credential")
  valid_21626016 = validateParameter(valid_21626016, JString, required = false,
                                   default = nil)
  if valid_21626016 != nil:
    section.add "X-Amz-Credential", valid_21626016
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

proc call*(call_21626018: Call_DisconnectParticipant_21626006;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_21626018.validator(path, query, header, formData, body, _)
  let scheme = call_21626018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626018.makeUrl(scheme.get, call_21626018.host, call_21626018.base,
                               call_21626018.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626018, uri, valid, _)

proc call*(call_21626019: Call_DisconnectParticipant_21626006; body: JsonNode): Recallable =
  ## disconnectParticipant
  ## Disconnects a participant. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_21626020 = newJObject()
  if body != nil:
    body_21626020 = body
  result = call_21626019.call(nil, nil, nil, nil, body_21626020)

var disconnectParticipant* = Call_DisconnectParticipant_21626006(
    name: "disconnectParticipant", meth: HttpMethod.HttpPost,
    host: "participant.connect.amazonaws.com",
    route: "/participant/disconnect#X-Amz-Bearer",
    validator: validate_DisconnectParticipant_21626007, base: "/",
    makeUrl: url_DisconnectParticipant_21626008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTranscript_21626021 = ref object of OpenApiRestCall_21625426
proc url_GetTranscript_21626023(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTranscript_21626022(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626024 = query.getOrDefault("NextToken")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "NextToken", valid_21626024
  var valid_21626025 = query.getOrDefault("MaxResults")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "MaxResults", valid_21626025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626026 = header.getOrDefault("X-Amz-Date")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Date", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Security-Token", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626028
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_21626029 = header.getOrDefault("X-Amz-Bearer")
  valid_21626029 = validateParameter(valid_21626029, JString, required = true,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Bearer", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Algorithm", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-Signature")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Signature", valid_21626031
  var valid_21626032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Credential")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Credential", valid_21626033
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

proc call*(call_21626035: Call_GetTranscript_21626021; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_21626035.validator(path, query, header, formData, body, _)
  let scheme = call_21626035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626035.makeUrl(scheme.get, call_21626035.host, call_21626035.base,
                               call_21626035.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626035, uri, valid, _)

proc call*(call_21626036: Call_GetTranscript_21626021; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getTranscript
  ## Retrieves a transcript of the session. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626038 = newJObject()
  var body_21626039 = newJObject()
  add(query_21626038, "NextToken", newJString(NextToken))
  if body != nil:
    body_21626039 = body
  add(query_21626038, "MaxResults", newJString(MaxResults))
  result = call_21626036.call(nil, query_21626038, nil, nil, body_21626039)

var getTranscript* = Call_GetTranscript_21626021(name: "getTranscript",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/transcript#X-Amz-Bearer",
    validator: validate_GetTranscript_21626022, base: "/",
    makeUrl: url_GetTranscript_21626023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEvent_21626043 = ref object of OpenApiRestCall_21625426
proc url_SendEvent_21626045(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEvent_21626044(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the participant's connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626046 = header.getOrDefault("X-Amz-Date")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Date", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Security-Token", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_21626049 = header.getOrDefault("X-Amz-Bearer")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Bearer", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Algorithm", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Signature")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Signature", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Credential")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Credential", valid_21626053
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

proc call*(call_21626055: Call_SendEvent_21626043; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_21626055.validator(path, query, header, formData, body, _)
  let scheme = call_21626055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626055.makeUrl(scheme.get, call_21626055.host, call_21626055.base,
                               call_21626055.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626055, uri, valid, _)

proc call*(call_21626056: Call_SendEvent_21626043; body: JsonNode): Recallable =
  ## sendEvent
  ## Sends an event. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_21626057 = newJObject()
  if body != nil:
    body_21626057 = body
  result = call_21626056.call(nil, nil, nil, nil, body_21626057)

var sendEvent* = Call_SendEvent_21626043(name: "sendEvent",
                                      meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
                                      route: "/participant/event#X-Amz-Bearer",
                                      validator: validate_SendEvent_21626044,
                                      base: "/", makeUrl: url_SendEvent_21626045,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendMessage_21626058 = ref object of OpenApiRestCall_21625426
proc url_SendMessage_21626060(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendMessage_21626059(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Bearer: JString (required)
  ##               : The authentication token associated with the connection.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626061 = header.getOrDefault("X-Amz-Date")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Date", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Security-Token", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626063
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Bearer` field"
  var valid_21626064 = header.getOrDefault("X-Amz-Bearer")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Bearer", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Algorithm", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Signature")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Signature", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Credential")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Credential", valid_21626068
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

proc call*(call_21626070: Call_SendMessage_21626058; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ## 
  let valid = call_21626070.validator(path, query, header, formData, body, _)
  let scheme = call_21626070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626070.makeUrl(scheme.get, call_21626070.host, call_21626070.base,
                               call_21626070.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626070, uri, valid, _)

proc call*(call_21626071: Call_SendMessage_21626058; body: JsonNode): Recallable =
  ## sendMessage
  ## Sends a message. Note that ConnectionToken is used for invoking this API instead of ParticipantToken.
  ##   body: JObject (required)
  var body_21626072 = newJObject()
  if body != nil:
    body_21626072 = body
  result = call_21626071.call(nil, nil, nil, nil, body_21626072)

var sendMessage* = Call_SendMessage_21626058(name: "sendMessage",
    meth: HttpMethod.HttpPost, host: "participant.connect.amazonaws.com",
    route: "/participant/message#X-Amz-Bearer", validator: validate_SendMessage_21626059,
    base: "/", makeUrl: url_SendMessage_21626060,
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