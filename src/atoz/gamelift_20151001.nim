
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon GameLift
## version: 2015-10-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon GameLift Service</fullname> <p> Amazon GameLift is a managed service for developers who need a scalable, dedicated server solution for their multiplayer games. Use Amazon GameLift for these tasks: (1) set up computing resources and deploy your game servers, (2) run game sessions and get players into games, (3) automatically scale your resources to meet player demand and manage costs, and (4) track in-depth metrics on game server performance and player usage.</p> <p>When setting up hosting resources, you can deploy your custom game server or use the Amazon GameLift Realtime Servers. Realtime Servers gives you the ability to quickly stand up lightweight, efficient game servers with the core Amazon GameLift infrastructure already built in.</p> <p> <b>Get Amazon GameLift Tools and Resources</b> </p> <p>This reference guide describes the low-level service API for Amazon GameLift and provides links to language-specific SDK reference topics. See also <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-components.html"> Amazon GameLift Tools and Resources</a>.</p> <p> <b>API Summary</b> </p> <p>The Amazon GameLift service API includes two key sets of actions:</p> <ul> <li> <p>Manage game sessions and player access -- Integrate this functionality into game client services in order to create new game sessions, retrieve information on existing game sessions; reserve a player slot in a game session, request matchmaking, etc.</p> </li> <li> <p>Configure and manage game server resources -- Manage your Amazon GameLift hosting resources, including builds, scripts, fleets, queues, and aliases. Set up matchmakers, configure auto-scaling, retrieve game logs, and get hosting and game metrics.</p> </li> </ul> <p> <b> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html"> Task-based list of API actions</a> </b> </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/gamelift/
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "gamelift.ap-northeast-1.amazonaws.com", "ap-southeast-1": "gamelift.ap-southeast-1.amazonaws.com",
                           "us-west-2": "gamelift.us-west-2.amazonaws.com",
                           "eu-west-2": "gamelift.eu-west-2.amazonaws.com", "ap-northeast-3": "gamelift.ap-northeast-3.amazonaws.com", "eu-central-1": "gamelift.eu-central-1.amazonaws.com",
                           "us-east-2": "gamelift.us-east-2.amazonaws.com",
                           "us-east-1": "gamelift.us-east-1.amazonaws.com", "cn-northwest-1": "gamelift.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "gamelift.ap-south-1.amazonaws.com",
                           "eu-north-1": "gamelift.eu-north-1.amazonaws.com", "ap-northeast-2": "gamelift.ap-northeast-2.amazonaws.com",
                           "us-west-1": "gamelift.us-west-1.amazonaws.com", "us-gov-east-1": "gamelift.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "gamelift.eu-west-3.amazonaws.com", "cn-north-1": "gamelift.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "gamelift.sa-east-1.amazonaws.com",
                           "eu-west-1": "gamelift.eu-west-1.amazonaws.com", "us-gov-west-1": "gamelift.us-gov-west-1.amazonaws.com", "ap-southeast-2": "gamelift.ap-southeast-2.amazonaws.com", "ca-central-1": "gamelift.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "gamelift.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "gamelift.ap-southeast-1.amazonaws.com",
      "us-west-2": "gamelift.us-west-2.amazonaws.com",
      "eu-west-2": "gamelift.eu-west-2.amazonaws.com",
      "ap-northeast-3": "gamelift.ap-northeast-3.amazonaws.com",
      "eu-central-1": "gamelift.eu-central-1.amazonaws.com",
      "us-east-2": "gamelift.us-east-2.amazonaws.com",
      "us-east-1": "gamelift.us-east-1.amazonaws.com",
      "cn-northwest-1": "gamelift.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "gamelift.ap-south-1.amazonaws.com",
      "eu-north-1": "gamelift.eu-north-1.amazonaws.com",
      "ap-northeast-2": "gamelift.ap-northeast-2.amazonaws.com",
      "us-west-1": "gamelift.us-west-1.amazonaws.com",
      "us-gov-east-1": "gamelift.us-gov-east-1.amazonaws.com",
      "eu-west-3": "gamelift.eu-west-3.amazonaws.com",
      "cn-north-1": "gamelift.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "gamelift.sa-east-1.amazonaws.com",
      "eu-west-1": "gamelift.eu-west-1.amazonaws.com",
      "us-gov-west-1": "gamelift.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "gamelift.ap-southeast-2.amazonaws.com",
      "ca-central-1": "gamelift.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "gamelift"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptMatch_593774 = ref object of OpenApiRestCall_593437
proc url_AcceptMatch_593776(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AcceptMatch_593775(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers a player's acceptance or rejection of a proposed FlexMatch match. A matchmaking configuration may require player acceptance; if so, then matches built with that configuration cannot be completed unless all players accept the proposed match within a specified time limit. </p> <p>When FlexMatch builds a match, all the matchmaking tickets involved in the proposed match are placed into status <code>REQUIRES_ACCEPTANCE</code>. This is a trigger for your game to get acceptance from all players in the ticket. Acceptances are only valid for tickets when they are in this status; all other acceptances result in an error.</p> <p>To register acceptance, specify the ticket ID, a response, and one or more players. Once all players have registered acceptance, the matchmaking tickets advance to status <code>PLACING</code>, where a new game session is created for the match. </p> <p>If any player rejects the match, or if acceptances are not received before a specified timeout, the proposed match is dropped. The matchmaking tickets are then handled in one of two ways: For tickets where one or more players rejected the match, the ticket status is returned to <code>SEARCHING</code> to find a new match. For tickets where one or more players failed to respond, the ticket status is set to <code>CANCELLED</code>, and processing is terminated. A new matchmaking request for these players can be submitted as needed. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-events.html"> FlexMatch Events Reference</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
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
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = newJString("GameLift.AcceptMatch"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AcceptMatch_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a player's acceptance or rejection of a proposed FlexMatch match. A matchmaking configuration may require player acceptance; if so, then matches built with that configuration cannot be completed unless all players accept the proposed match within a specified time limit. </p> <p>When FlexMatch builds a match, all the matchmaking tickets involved in the proposed match are placed into status <code>REQUIRES_ACCEPTANCE</code>. This is a trigger for your game to get acceptance from all players in the ticket. Acceptances are only valid for tickets when they are in this status; all other acceptances result in an error.</p> <p>To register acceptance, specify the ticket ID, a response, and one or more players. Once all players have registered acceptance, the matchmaking tickets advance to status <code>PLACING</code>, where a new game session is created for the match. </p> <p>If any player rejects the match, or if acceptances are not received before a specified timeout, the proposed match is dropped. The matchmaking tickets are then handled in one of two ways: For tickets where one or more players rejected the match, the ticket status is returned to <code>SEARCHING</code> to find a new match. For tickets where one or more players failed to respond, the ticket status is set to <code>CANCELLED</code>, and processing is terminated. A new matchmaking request for these players can be submitted as needed. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-events.html"> FlexMatch Events Reference</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AcceptMatch_593774; body: JsonNode): Recallable =
  ## acceptMatch
  ## <p>Registers a player's acceptance or rejection of a proposed FlexMatch match. A matchmaking configuration may require player acceptance; if so, then matches built with that configuration cannot be completed unless all players accept the proposed match within a specified time limit. </p> <p>When FlexMatch builds a match, all the matchmaking tickets involved in the proposed match are placed into status <code>REQUIRES_ACCEPTANCE</code>. This is a trigger for your game to get acceptance from all players in the ticket. Acceptances are only valid for tickets when they are in this status; all other acceptances result in an error.</p> <p>To register acceptance, specify the ticket ID, a response, and one or more players. Once all players have registered acceptance, the matchmaking tickets advance to status <code>PLACING</code>, where a new game session is created for the match. </p> <p>If any player rejects the match, or if acceptances are not received before a specified timeout, the proposed match is dropped. The matchmaking tickets are then handled in one of two ways: For tickets where one or more players rejected the match, the ticket status is returned to <code>SEARCHING</code> to find a new match. For tickets where one or more players failed to respond, the ticket status is set to <code>CANCELLED</code>, and processing is terminated. A new matchmaking request for these players can be submitted as needed. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-events.html"> FlexMatch Events Reference</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var acceptMatch* = Call_AcceptMatch_593774(name: "acceptMatch",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.AcceptMatch",
                                        validator: validate_AcceptMatch_593775,
                                        base: "/", url: url_AcceptMatch_593776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_594043 = ref object of OpenApiRestCall_593437
proc url_CreateAlias_594045(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAlias_594044(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an alias for a fleet. In most situations, you can use an alias ID in place of a fleet ID. By using a fleet alias instead of a specific fleet ID, you can switch gameplay and players to a new fleet without changing your game client or other game components. For example, for games in production, using an alias allows you to seamlessly redirect your player base to a new game server update. </p> <p>Amazon GameLift supports two types of routing strategies for aliases: simple and terminal. A simple alias points to an active fleet. A terminal alias is used to display messaging or link to a URL instead of routing players to an active fleet. For example, you might use a terminal alias when a game version is no longer supported and you want to direct players to an upgrade site. </p> <p>To create a fleet alias, specify an alias name, routing strategy, and optional description. Each simple alias can point to only one fleet, but a fleet can have multiple aliases. If successful, a new alias record is returned, including an alias ID, which you can reference when creating a game session. You can reassign an alias to another fleet by calling <code>UpdateAlias</code>.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
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
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true,
                                 default = newJString("GameLift.CreateAlias"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_CreateAlias_594043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for a fleet. In most situations, you can use an alias ID in place of a fleet ID. By using a fleet alias instead of a specific fleet ID, you can switch gameplay and players to a new fleet without changing your game client or other game components. For example, for games in production, using an alias allows you to seamlessly redirect your player base to a new game server update. </p> <p>Amazon GameLift supports two types of routing strategies for aliases: simple and terminal. A simple alias points to an active fleet. A terminal alias is used to display messaging or link to a URL instead of routing players to an active fleet. For example, you might use a terminal alias when a game version is no longer supported and you want to direct players to an upgrade site. </p> <p>To create a fleet alias, specify an alias name, routing strategy, and optional description. Each simple alias can point to only one fleet, but a fleet can have multiple aliases. If successful, a new alias record is returned, including an alias ID, which you can reference when creating a game session. You can reassign an alias to another fleet by calling <code>UpdateAlias</code>.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_CreateAlias_594043; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an alias for a fleet. In most situations, you can use an alias ID in place of a fleet ID. By using a fleet alias instead of a specific fleet ID, you can switch gameplay and players to a new fleet without changing your game client or other game components. For example, for games in production, using an alias allows you to seamlessly redirect your player base to a new game server update. </p> <p>Amazon GameLift supports two types of routing strategies for aliases: simple and terminal. A simple alias points to an active fleet. A terminal alias is used to display messaging or link to a URL instead of routing players to an active fleet. For example, you might use a terminal alias when a game version is no longer supported and you want to direct players to an upgrade site. </p> <p>To create a fleet alias, specify an alias name, routing strategy, and optional description. Each simple alias can point to only one fleet, but a fleet can have multiple aliases. If successful, a new alias record is returned, including an alias ID, which you can reference when creating a game session. You can reassign an alias to another fleet by calling <code>UpdateAlias</code>.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var createAlias* = Call_CreateAlias_594043(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.CreateAlias",
                                        validator: validate_CreateAlias_594044,
                                        base: "/", url: url_CreateAlias_594045,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBuild_594058 = ref object of OpenApiRestCall_593437
proc url_CreateBuild_594060(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBuild_594059(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new Amazon GameLift build record for your game server binary files and points to the location of your game server build files in an Amazon Simple Storage Service (Amazon S3) location. </p> <p>Game server binaries must be combined into a <code>.zip</code> file for use with Amazon GameLift. </p> <important> <p>To create new builds quickly and easily, use the AWS CLI command <b> <a href="https://docs.aws.amazon.com/cli/latest/reference/gamelift/upload-build.html">upload-build</a> </b>. This helper command uploads your build and creates a new build record in one step, and automatically handles the necessary permissions. </p> </important> <p>The <code>CreateBuild</code> operation should be used only when you need to manually upload your build files, as in the following scenarios:</p> <ul> <li> <p>Store a build file in an Amazon S3 bucket under your own AWS account. To use this option, you must first give Amazon GameLift access to that Amazon S3 bucket. To create a new build record using files in your Amazon S3 bucket, call <code>CreateBuild</code> and specify a build name, operating system, and the storage location of your game build.</p> </li> <li> <p>Upload a build file directly to Amazon GameLift's Amazon S3 account. To use this option, you first call <code>CreateBuild</code> with a build name and operating system. This action creates a new build record and returns an Amazon S3 storage location (bucket and key only) and temporary access credentials. Use the credentials to manually upload your build file to the storage location (see the Amazon S3 topic <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UploadingObjects.html">Uploading Objects</a>). You can upload files to a location only once. </p> </li> </ul> <p>If successful, this operation creates a new build record with a unique build ID and places it in <code>INITIALIZED</code> status. You can use <a>DescribeBuild</a> to check the status of your build. A build must be in <code>READY</code> status before it can be used to create fleets.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html">Uploading Your Game</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-cli-uploading.html#gamelift-build-cli-uploading-create-build"> Create a Build with Files in Amazon S3</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
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
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true,
                                 default = newJString("GameLift.CreateBuild"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_CreateBuild_594058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon GameLift build record for your game server binary files and points to the location of your game server build files in an Amazon Simple Storage Service (Amazon S3) location. </p> <p>Game server binaries must be combined into a <code>.zip</code> file for use with Amazon GameLift. </p> <important> <p>To create new builds quickly and easily, use the AWS CLI command <b> <a href="https://docs.aws.amazon.com/cli/latest/reference/gamelift/upload-build.html">upload-build</a> </b>. This helper command uploads your build and creates a new build record in one step, and automatically handles the necessary permissions. </p> </important> <p>The <code>CreateBuild</code> operation should be used only when you need to manually upload your build files, as in the following scenarios:</p> <ul> <li> <p>Store a build file in an Amazon S3 bucket under your own AWS account. To use this option, you must first give Amazon GameLift access to that Amazon S3 bucket. To create a new build record using files in your Amazon S3 bucket, call <code>CreateBuild</code> and specify a build name, operating system, and the storage location of your game build.</p> </li> <li> <p>Upload a build file directly to Amazon GameLift's Amazon S3 account. To use this option, you first call <code>CreateBuild</code> with a build name and operating system. This action creates a new build record and returns an Amazon S3 storage location (bucket and key only) and temporary access credentials. Use the credentials to manually upload your build file to the storage location (see the Amazon S3 topic <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UploadingObjects.html">Uploading Objects</a>). You can upload files to a location only once. </p> </li> </ul> <p>If successful, this operation creates a new build record with a unique build ID and places it in <code>INITIALIZED</code> status. You can use <a>DescribeBuild</a> to check the status of your build. A build must be in <code>READY</code> status before it can be used to create fleets.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html">Uploading Your Game</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-cli-uploading.html#gamelift-build-cli-uploading-create-build"> Create a Build with Files in Amazon S3</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_CreateBuild_594058; body: JsonNode): Recallable =
  ## createBuild
  ## <p>Creates a new Amazon GameLift build record for your game server binary files and points to the location of your game server build files in an Amazon Simple Storage Service (Amazon S3) location. </p> <p>Game server binaries must be combined into a <code>.zip</code> file for use with Amazon GameLift. </p> <important> <p>To create new builds quickly and easily, use the AWS CLI command <b> <a href="https://docs.aws.amazon.com/cli/latest/reference/gamelift/upload-build.html">upload-build</a> </b>. This helper command uploads your build and creates a new build record in one step, and automatically handles the necessary permissions. </p> </important> <p>The <code>CreateBuild</code> operation should be used only when you need to manually upload your build files, as in the following scenarios:</p> <ul> <li> <p>Store a build file in an Amazon S3 bucket under your own AWS account. To use this option, you must first give Amazon GameLift access to that Amazon S3 bucket. To create a new build record using files in your Amazon S3 bucket, call <code>CreateBuild</code> and specify a build name, operating system, and the storage location of your game build.</p> </li> <li> <p>Upload a build file directly to Amazon GameLift's Amazon S3 account. To use this option, you first call <code>CreateBuild</code> with a build name and operating system. This action creates a new build record and returns an Amazon S3 storage location (bucket and key only) and temporary access credentials. Use the credentials to manually upload your build file to the storage location (see the Amazon S3 topic <a href="https://docs.aws.amazon.com/AmazonS3/latest/dev/UploadingObjects.html">Uploading Objects</a>). You can upload files to a location only once. </p> </li> </ul> <p>If successful, this operation creates a new build record with a unique build ID and places it in <code>INITIALIZED</code> status. You can use <a>DescribeBuild</a> to check the status of your build. A build must be in <code>READY</code> status before it can be used to create fleets.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html">Uploading Your Game</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-cli-uploading.html#gamelift-build-cli-uploading-create-build"> Create a Build with Files in Amazon S3</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var createBuild* = Call_CreateBuild_594058(name: "createBuild",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.CreateBuild",
                                        validator: validate_CreateBuild_594059,
                                        base: "/", url: url_CreateBuild_594060,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_594073 = ref object of OpenApiRestCall_593437
proc url_CreateFleet_594075(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFleet_594074(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new fleet to run your game servers. whether they are custom game builds or Realtime Servers with game-specific script. A fleet is a set of Amazon Elastic Compute Cloud (Amazon EC2) instances, each of which can host multiple game sessions. When creating a fleet, you choose the hardware specifications, set some configuration options, and specify the game server to deploy on the new fleet. </p> <p>To create a new fleet, you must provide the following: (1) a fleet name, (2) an EC2 instance type and fleet type (spot or on-demand), (3) the build ID for your game build or script ID if using Realtime Servers, and (4) a run-time configuration, which determines how game servers will run on each instance in the fleet. </p> <note> <p>When creating a Realtime Servers fleet, we recommend using a minimal version of the Realtime script (see this <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-script.html#realtime-script-examples"> working code example </a>). This will make it much easier to troubleshoot any fleet creation issues. Once the fleet is active, you can update your Realtime script as needed.</p> </note> <p>If the <code>CreateFleet</code> call is successful, Amazon GameLift performs the following tasks. You can track the process of a fleet by checking the fleet status or by monitoring fleet creation events:</p> <ul> <li> <p>Creates a fleet record. Status: <code>NEW</code>.</p> </li> <li> <p>Begins writing events to the fleet event log, which can be accessed in the Amazon GameLift console.</p> <p>Sets the fleet's target capacity to 1 (desired instances), which triggers Amazon GameLift to start one new EC2 instance.</p> </li> <li> <p>Downloads the game build or Realtime script to the new instance and installs it. Statuses: <code>DOWNLOADING</code>, <code>VALIDATING</code>, <code>BUILDING</code>. </p> </li> <li> <p>Starts launching server processes on the instance. If the fleet is configured to run multiple server processes per instance, Amazon GameLift staggers each launch by a few seconds. Status: <code>ACTIVATING</code>.</p> </li> <li> <p>Sets the fleet's status to <code>ACTIVE</code> as soon as one server process is ready to host a game session.</p> </li> </ul> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-debug.html"> Debug Fleet Creation Issues</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = newJString("GameLift.CreateFleet"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateFleet_594073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new fleet to run your game servers. whether they are custom game builds or Realtime Servers with game-specific script. A fleet is a set of Amazon Elastic Compute Cloud (Amazon EC2) instances, each of which can host multiple game sessions. When creating a fleet, you choose the hardware specifications, set some configuration options, and specify the game server to deploy on the new fleet. </p> <p>To create a new fleet, you must provide the following: (1) a fleet name, (2) an EC2 instance type and fleet type (spot or on-demand), (3) the build ID for your game build or script ID if using Realtime Servers, and (4) a run-time configuration, which determines how game servers will run on each instance in the fleet. </p> <note> <p>When creating a Realtime Servers fleet, we recommend using a minimal version of the Realtime script (see this <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-script.html#realtime-script-examples"> working code example </a>). This will make it much easier to troubleshoot any fleet creation issues. Once the fleet is active, you can update your Realtime script as needed.</p> </note> <p>If the <code>CreateFleet</code> call is successful, Amazon GameLift performs the following tasks. You can track the process of a fleet by checking the fleet status or by monitoring fleet creation events:</p> <ul> <li> <p>Creates a fleet record. Status: <code>NEW</code>.</p> </li> <li> <p>Begins writing events to the fleet event log, which can be accessed in the Amazon GameLift console.</p> <p>Sets the fleet's target capacity to 1 (desired instances), which triggers Amazon GameLift to start one new EC2 instance.</p> </li> <li> <p>Downloads the game build or Realtime script to the new instance and installs it. Statuses: <code>DOWNLOADING</code>, <code>VALIDATING</code>, <code>BUILDING</code>. </p> </li> <li> <p>Starts launching server processes on the instance. If the fleet is configured to run multiple server processes per instance, Amazon GameLift staggers each launch by a few seconds. Status: <code>ACTIVATING</code>.</p> </li> <li> <p>Sets the fleet's status to <code>ACTIVE</code> as soon as one server process is ready to host a game session.</p> </li> </ul> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-debug.html"> Debug Fleet Creation Issues</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateFleet_594073; body: JsonNode): Recallable =
  ## createFleet
  ## <p>Creates a new fleet to run your game servers. whether they are custom game builds or Realtime Servers with game-specific script. A fleet is a set of Amazon Elastic Compute Cloud (Amazon EC2) instances, each of which can host multiple game sessions. When creating a fleet, you choose the hardware specifications, set some configuration options, and specify the game server to deploy on the new fleet. </p> <p>To create a new fleet, you must provide the following: (1) a fleet name, (2) an EC2 instance type and fleet type (spot or on-demand), (3) the build ID for your game build or script ID if using Realtime Servers, and (4) a run-time configuration, which determines how game servers will run on each instance in the fleet. </p> <note> <p>When creating a Realtime Servers fleet, we recommend using a minimal version of the Realtime script (see this <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-script.html#realtime-script-examples"> working code example </a>). This will make it much easier to troubleshoot any fleet creation issues. Once the fleet is active, you can update your Realtime script as needed.</p> </note> <p>If the <code>CreateFleet</code> call is successful, Amazon GameLift performs the following tasks. You can track the process of a fleet by checking the fleet status or by monitoring fleet creation events:</p> <ul> <li> <p>Creates a fleet record. Status: <code>NEW</code>.</p> </li> <li> <p>Begins writing events to the fleet event log, which can be accessed in the Amazon GameLift console.</p> <p>Sets the fleet's target capacity to 1 (desired instances), which triggers Amazon GameLift to start one new EC2 instance.</p> </li> <li> <p>Downloads the game build or Realtime script to the new instance and installs it. Statuses: <code>DOWNLOADING</code>, <code>VALIDATING</code>, <code>BUILDING</code>. </p> </li> <li> <p>Starts launching server processes on the instance. If the fleet is configured to run multiple server processes per instance, Amazon GameLift staggers each launch by a few seconds. Status: <code>ACTIVATING</code>.</p> </li> <li> <p>Sets the fleet's status to <code>ACTIVE</code> as soon as one server process is ready to host a game session.</p> </li> </ul> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-debug.html"> Debug Fleet Creation Issues</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createFleet* = Call_CreateFleet_594073(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.CreateFleet",
                                        validator: validate_CreateFleet_594074,
                                        base: "/", url: url_CreateFleet_594075,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGameSession_594088 = ref object of OpenApiRestCall_593437
proc url_CreateGameSession_594090(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGameSession_594089(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a multiplayer game session for players. This action creates a game session record and assigns an available server process in the specified fleet to host the game session. A fleet must have an <code>ACTIVE</code> status before a game session can be created in it.</p> <p>To create a game session, specify either fleet ID or alias ID and indicate a maximum number of players to allow in the game session. You can also provide a name and game-specific properties for this game session. If successful, a <a>GameSession</a> object is returned containing the game session properties and other settings you specified.</p> <p> <b>Idempotency tokens.</b> You can add a token that uniquely identifies game session requests. This is useful for ensuring that game session requests are idempotent. Multiple requests with the same idempotency token are processed only once; subsequent requests return the original result. All response values are the same with the exception of game session status, which may change.</p> <p> <b>Resource creation limits.</b> If you are creating a game session on a fleet with a resource creation limit policy in force, then you must specify a creator ID. Without this ID, Amazon GameLift has no way to evaluate the policy for this new game session request.</p> <p> <b>Player acceptance policy.</b> By default, newly created game sessions are open to new players. You can restrict new player access by using <a>UpdateGameSession</a> to change the game session's player session creation policy.</p> <p> <b>Game session logs.</b> Logs are retained for all active game sessions for 14 days. To access the logs, call <a>GetGameSessionLogUrl</a> to download the log files.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "GameLift.CreateGameSession"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_CreateGameSession_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a multiplayer game session for players. This action creates a game session record and assigns an available server process in the specified fleet to host the game session. A fleet must have an <code>ACTIVE</code> status before a game session can be created in it.</p> <p>To create a game session, specify either fleet ID or alias ID and indicate a maximum number of players to allow in the game session. You can also provide a name and game-specific properties for this game session. If successful, a <a>GameSession</a> object is returned containing the game session properties and other settings you specified.</p> <p> <b>Idempotency tokens.</b> You can add a token that uniquely identifies game session requests. This is useful for ensuring that game session requests are idempotent. Multiple requests with the same idempotency token are processed only once; subsequent requests return the original result. All response values are the same with the exception of game session status, which may change.</p> <p> <b>Resource creation limits.</b> If you are creating a game session on a fleet with a resource creation limit policy in force, then you must specify a creator ID. Without this ID, Amazon GameLift has no way to evaluate the policy for this new game session request.</p> <p> <b>Player acceptance policy.</b> By default, newly created game sessions are open to new players. You can restrict new player access by using <a>UpdateGameSession</a> to change the game session's player session creation policy.</p> <p> <b>Game session logs.</b> Logs are retained for all active game sessions for 14 days. To access the logs, call <a>GetGameSessionLogUrl</a> to download the log files.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_CreateGameSession_594088; body: JsonNode): Recallable =
  ## createGameSession
  ## <p>Creates a multiplayer game session for players. This action creates a game session record and assigns an available server process in the specified fleet to host the game session. A fleet must have an <code>ACTIVE</code> status before a game session can be created in it.</p> <p>To create a game session, specify either fleet ID or alias ID and indicate a maximum number of players to allow in the game session. You can also provide a name and game-specific properties for this game session. If successful, a <a>GameSession</a> object is returned containing the game session properties and other settings you specified.</p> <p> <b>Idempotency tokens.</b> You can add a token that uniquely identifies game session requests. This is useful for ensuring that game session requests are idempotent. Multiple requests with the same idempotency token are processed only once; subsequent requests return the original result. All response values are the same with the exception of game session status, which may change.</p> <p> <b>Resource creation limits.</b> If you are creating a game session on a fleet with a resource creation limit policy in force, then you must specify a creator ID. Without this ID, Amazon GameLift has no way to evaluate the policy for this new game session request.</p> <p> <b>Player acceptance policy.</b> By default, newly created game sessions are open to new players. You can restrict new player access by using <a>UpdateGameSession</a> to change the game session's player session creation policy.</p> <p> <b>Game session logs.</b> Logs are retained for all active game sessions for 14 days. To access the logs, call <a>GetGameSessionLogUrl</a> to download the log files.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var createGameSession* = Call_CreateGameSession_594088(name: "createGameSession",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreateGameSession",
    validator: validate_CreateGameSession_594089, base: "/",
    url: url_CreateGameSession_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGameSessionQueue_594103 = ref object of OpenApiRestCall_593437
proc url_CreateGameSessionQueue_594105(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGameSessionQueue_594104(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Establishes a new queue for processing requests to place new game sessions. A queue identifies where new game sessions can be hosted -- by specifying a list of destinations (fleets or aliases) -- and how long requests can wait in the queue before timing out. You can set up a queue to try to place game sessions on fleets in multiple regions. To add placement requests to a queue, call <a>StartGameSessionPlacement</a> and reference the queue name.</p> <p> <b>Destination order.</b> When processing a request for a game session, Amazon GameLift tries each destination in order until it finds one with available resources to host the new game session. A queue's default order is determined by how destinations are listed. The default order is overridden when a game session placement request provides player latency information. Player latency information enables Amazon GameLift to prioritize destinations where players report the lowest average latency, as a result placing the new game session where the majority of players will have the best possible gameplay experience.</p> <p> <b>Player latency policies.</b> For placement requests containing player latency information, use player latency policies to protect individual players from very high latencies. With a latency cap, even when a destination can deliver a low latency for most players, the game is not placed where any individual player is reporting latency higher than a policy's maximum. A queue can have multiple latency policies, which are enforced consecutively starting with the policy with the lowest latency cap. Use multiple policies to gradually relax latency controls; for example, you might set a policy with a low latency cap for the first 60 seconds, a second policy with a higher cap for the next 60 seconds, etc. </p> <p>To create a new queue, provide a name, timeout value, a list of destinations and, if desired, a set of latency policies. If successful, a new queue object is returned.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "GameLift.CreateGameSessionQueue"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreateGameSessionQueue_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Establishes a new queue for processing requests to place new game sessions. A queue identifies where new game sessions can be hosted -- by specifying a list of destinations (fleets or aliases) -- and how long requests can wait in the queue before timing out. You can set up a queue to try to place game sessions on fleets in multiple regions. To add placement requests to a queue, call <a>StartGameSessionPlacement</a> and reference the queue name.</p> <p> <b>Destination order.</b> When processing a request for a game session, Amazon GameLift tries each destination in order until it finds one with available resources to host the new game session. A queue's default order is determined by how destinations are listed. The default order is overridden when a game session placement request provides player latency information. Player latency information enables Amazon GameLift to prioritize destinations where players report the lowest average latency, as a result placing the new game session where the majority of players will have the best possible gameplay experience.</p> <p> <b>Player latency policies.</b> For placement requests containing player latency information, use player latency policies to protect individual players from very high latencies. With a latency cap, even when a destination can deliver a low latency for most players, the game is not placed where any individual player is reporting latency higher than a policy's maximum. A queue can have multiple latency policies, which are enforced consecutively starting with the policy with the lowest latency cap. Use multiple policies to gradually relax latency controls; for example, you might set a policy with a low latency cap for the first 60 seconds, a second policy with a higher cap for the next 60 seconds, etc. </p> <p>To create a new queue, provide a name, timeout value, a list of destinations and, if desired, a set of latency policies. If successful, a new queue object is returned.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreateGameSessionQueue_594103; body: JsonNode): Recallable =
  ## createGameSessionQueue
  ## <p>Establishes a new queue for processing requests to place new game sessions. A queue identifies where new game sessions can be hosted -- by specifying a list of destinations (fleets or aliases) -- and how long requests can wait in the queue before timing out. You can set up a queue to try to place game sessions on fleets in multiple regions. To add placement requests to a queue, call <a>StartGameSessionPlacement</a> and reference the queue name.</p> <p> <b>Destination order.</b> When processing a request for a game session, Amazon GameLift tries each destination in order until it finds one with available resources to host the new game session. A queue's default order is determined by how destinations are listed. The default order is overridden when a game session placement request provides player latency information. Player latency information enables Amazon GameLift to prioritize destinations where players report the lowest average latency, as a result placing the new game session where the majority of players will have the best possible gameplay experience.</p> <p> <b>Player latency policies.</b> For placement requests containing player latency information, use player latency policies to protect individual players from very high latencies. With a latency cap, even when a destination can deliver a low latency for most players, the game is not placed where any individual player is reporting latency higher than a policy's maximum. A queue can have multiple latency policies, which are enforced consecutively starting with the policy with the lowest latency cap. Use multiple policies to gradually relax latency controls; for example, you might set a policy with a low latency cap for the first 60 seconds, a second policy with a higher cap for the next 60 seconds, etc. </p> <p>To create a new queue, provide a name, timeout value, a list of destinations and, if desired, a set of latency policies. If successful, a new queue object is returned.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createGameSessionQueue* = Call_CreateGameSessionQueue_594103(
    name: "createGameSessionQueue", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreateGameSessionQueue",
    validator: validate_CreateGameSessionQueue_594104, base: "/",
    url: url_CreateGameSessionQueue_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMatchmakingConfiguration_594118 = ref object of OpenApiRestCall_593437
proc url_CreateMatchmakingConfiguration_594120(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMatchmakingConfiguration_594119(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Defines a new matchmaking configuration for use with FlexMatch. A matchmaking configuration sets out guidelines for matching players and getting the matches into games. You can set up multiple matchmaking configurations to handle the scenarios needed for your game. Each matchmaking ticket (<a>StartMatchmaking</a> or <a>StartMatchBackfill</a>) specifies a configuration for the match and provides player attributes to support the configuration being used. </p> <p>To create a matchmaking configuration, at a minimum you must specify the following: configuration name; a rule set that governs how to evaluate players and find acceptable matches; a game session queue to use when placing a new game session for the match; and the maximum time allowed for a matchmaking attempt.</p> <p>There are two ways to track the progress of matchmaking tickets: (1) polling ticket status with <a>DescribeMatchmaking</a>; or (2) receiving notifications with Amazon Simple Notification Service (SNS). To use notifications, you first need to set up an SNS topic to receive the notifications, and provide the topic ARN in the matchmaking configuration. Since notifications promise only "best effort" delivery, we recommend calling <code>DescribeMatchmaking</code> if no notifications are received within 30 seconds.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html"> Design a FlexMatch Matchmaker</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-notification.html"> Setting up Notifications for Matchmaking</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "GameLift.CreateMatchmakingConfiguration"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_CreateMatchmakingConfiguration_594118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Defines a new matchmaking configuration for use with FlexMatch. A matchmaking configuration sets out guidelines for matching players and getting the matches into games. You can set up multiple matchmaking configurations to handle the scenarios needed for your game. Each matchmaking ticket (<a>StartMatchmaking</a> or <a>StartMatchBackfill</a>) specifies a configuration for the match and provides player attributes to support the configuration being used. </p> <p>To create a matchmaking configuration, at a minimum you must specify the following: configuration name; a rule set that governs how to evaluate players and find acceptable matches; a game session queue to use when placing a new game session for the match; and the maximum time allowed for a matchmaking attempt.</p> <p>There are two ways to track the progress of matchmaking tickets: (1) polling ticket status with <a>DescribeMatchmaking</a>; or (2) receiving notifications with Amazon Simple Notification Service (SNS). To use notifications, you first need to set up an SNS topic to receive the notifications, and provide the topic ARN in the matchmaking configuration. Since notifications promise only "best effort" delivery, we recommend calling <code>DescribeMatchmaking</code> if no notifications are received within 30 seconds.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html"> Design a FlexMatch Matchmaker</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-notification.html"> Setting up Notifications for Matchmaking</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_CreateMatchmakingConfiguration_594118; body: JsonNode): Recallable =
  ## createMatchmakingConfiguration
  ## <p>Defines a new matchmaking configuration for use with FlexMatch. A matchmaking configuration sets out guidelines for matching players and getting the matches into games. You can set up multiple matchmaking configurations to handle the scenarios needed for your game. Each matchmaking ticket (<a>StartMatchmaking</a> or <a>StartMatchBackfill</a>) specifies a configuration for the match and provides player attributes to support the configuration being used. </p> <p>To create a matchmaking configuration, at a minimum you must specify the following: configuration name; a rule set that governs how to evaluate players and find acceptable matches; a game session queue to use when placing a new game session for the match; and the maximum time allowed for a matchmaking attempt.</p> <p>There are two ways to track the progress of matchmaking tickets: (1) polling ticket status with <a>DescribeMatchmaking</a>; or (2) receiving notifications with Amazon Simple Notification Service (SNS). To use notifications, you first need to set up an SNS topic to receive the notifications, and provide the topic ARN in the matchmaking configuration. Since notifications promise only "best effort" delivery, we recommend calling <code>DescribeMatchmaking</code> if no notifications are received within 30 seconds.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html"> Design a FlexMatch Matchmaker</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-notification.html"> Setting up Notifications for Matchmaking</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var createMatchmakingConfiguration* = Call_CreateMatchmakingConfiguration_594118(
    name: "createMatchmakingConfiguration", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreateMatchmakingConfiguration",
    validator: validate_CreateMatchmakingConfiguration_594119, base: "/",
    url: url_CreateMatchmakingConfiguration_594120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMatchmakingRuleSet_594133 = ref object of OpenApiRestCall_593437
proc url_CreateMatchmakingRuleSet_594135(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMatchmakingRuleSet_594134(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new rule set for FlexMatch matchmaking. A rule set describes the type of match to create, such as the number and size of teams, and sets the parameters for acceptable player matches, such as minimum skill level or character type. A rule set is used by a <a>MatchmakingConfiguration</a>. </p> <p>To create a matchmaking rule set, provide unique rule set name and the rule set body in JSON format. Rule sets must be defined in the same region as the matchmaking configuration they are used with.</p> <p>Since matchmaking rule sets cannot be edited, it is a good idea to check the rule set syntax using <a>ValidateMatchmakingRuleSet</a> before creating a new rule set.</p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html">Design a Matchmaker</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-intro.html">Matchmaking with FlexMatch</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "GameLift.CreateMatchmakingRuleSet"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_CreateMatchmakingRuleSet_594133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new rule set for FlexMatch matchmaking. A rule set describes the type of match to create, such as the number and size of teams, and sets the parameters for acceptable player matches, such as minimum skill level or character type. A rule set is used by a <a>MatchmakingConfiguration</a>. </p> <p>To create a matchmaking rule set, provide unique rule set name and the rule set body in JSON format. Rule sets must be defined in the same region as the matchmaking configuration they are used with.</p> <p>Since matchmaking rule sets cannot be edited, it is a good idea to check the rule set syntax using <a>ValidateMatchmakingRuleSet</a> before creating a new rule set.</p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html">Design a Matchmaker</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-intro.html">Matchmaking with FlexMatch</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_CreateMatchmakingRuleSet_594133; body: JsonNode): Recallable =
  ## createMatchmakingRuleSet
  ## <p>Creates a new rule set for FlexMatch matchmaking. A rule set describes the type of match to create, such as the number and size of teams, and sets the parameters for acceptable player matches, such as minimum skill level or character type. A rule set is used by a <a>MatchmakingConfiguration</a>. </p> <p>To create a matchmaking rule set, provide unique rule set name and the rule set body in JSON format. Rule sets must be defined in the same region as the matchmaking configuration they are used with.</p> <p>Since matchmaking rule sets cannot be edited, it is a good idea to check the rule set syntax using <a>ValidateMatchmakingRuleSet</a> before creating a new rule set.</p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html">Design a Matchmaker</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-intro.html">Matchmaking with FlexMatch</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var createMatchmakingRuleSet* = Call_CreateMatchmakingRuleSet_594133(
    name: "createMatchmakingRuleSet", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreateMatchmakingRuleSet",
    validator: validate_CreateMatchmakingRuleSet_594134, base: "/",
    url: url_CreateMatchmakingRuleSet_594135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlayerSession_594148 = ref object of OpenApiRestCall_593437
proc url_CreatePlayerSession_594150(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePlayerSession_594149(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Reserves an open player slot in an active game session. Before a player can be added, a game session must have an <code>ACTIVE</code> status, have a creation policy of <code>ALLOW_ALL</code>, and have an open player slot. To add a group of players to a game session, use <a>CreatePlayerSessions</a>. When the player connects to the game server and references a player session ID, the game server contacts the Amazon GameLift service to validate the player reservation and accept the player.</p> <p>To create a player session, specify a game session ID, player ID, and optionally a string of player data. If successful, a slot is reserved in the game session for the player and a new <a>PlayerSession</a> object is returned. Player sessions cannot be updated. </p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "GameLift.CreatePlayerSession"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_CreatePlayerSession_594148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reserves an open player slot in an active game session. Before a player can be added, a game session must have an <code>ACTIVE</code> status, have a creation policy of <code>ALLOW_ALL</code>, and have an open player slot. To add a group of players to a game session, use <a>CreatePlayerSessions</a>. When the player connects to the game server and references a player session ID, the game server contacts the Amazon GameLift service to validate the player reservation and accept the player.</p> <p>To create a player session, specify a game session ID, player ID, and optionally a string of player data. If successful, a slot is reserved in the game session for the player and a new <a>PlayerSession</a> object is returned. Player sessions cannot be updated. </p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_CreatePlayerSession_594148; body: JsonNode): Recallable =
  ## createPlayerSession
  ## <p>Reserves an open player slot in an active game session. Before a player can be added, a game session must have an <code>ACTIVE</code> status, have a creation policy of <code>ALLOW_ALL</code>, and have an open player slot. To add a group of players to a game session, use <a>CreatePlayerSessions</a>. When the player connects to the game server and references a player session ID, the game server contacts the Amazon GameLift service to validate the player reservation and accept the player.</p> <p>To create a player session, specify a game session ID, player ID, and optionally a string of player data. If successful, a slot is reserved in the game session for the player and a new <a>PlayerSession</a> object is returned. Player sessions cannot be updated. </p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var createPlayerSession* = Call_CreatePlayerSession_594148(
    name: "createPlayerSession", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreatePlayerSession",
    validator: validate_CreatePlayerSession_594149, base: "/",
    url: url_CreatePlayerSession_594150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePlayerSessions_594163 = ref object of OpenApiRestCall_593437
proc url_CreatePlayerSessions_594165(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePlayerSessions_594164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Reserves open slots in a game session for a group of players. Before players can be added, a game session must have an <code>ACTIVE</code> status, have a creation policy of <code>ALLOW_ALL</code>, and have an open player slot. To add a single player to a game session, use <a>CreatePlayerSession</a>. When a player connects to the game server and references a player session ID, the game server contacts the Amazon GameLift service to validate the player reservation and accept the player.</p> <p>To create player sessions, specify a game session ID, a list of player IDs, and optionally a set of player data strings. If successful, a slot is reserved in the game session for each player and a set of new <a>PlayerSession</a> objects is returned. Player sessions cannot be updated.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "GameLift.CreatePlayerSessions"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_CreatePlayerSessions_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Reserves open slots in a game session for a group of players. Before players can be added, a game session must have an <code>ACTIVE</code> status, have a creation policy of <code>ALLOW_ALL</code>, and have an open player slot. To add a single player to a game session, use <a>CreatePlayerSession</a>. When a player connects to the game server and references a player session ID, the game server contacts the Amazon GameLift service to validate the player reservation and accept the player.</p> <p>To create player sessions, specify a game session ID, a list of player IDs, and optionally a set of player data strings. If successful, a slot is reserved in the game session for each player and a set of new <a>PlayerSession</a> objects is returned. Player sessions cannot be updated.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_CreatePlayerSessions_594163; body: JsonNode): Recallable =
  ## createPlayerSessions
  ## <p>Reserves open slots in a game session for a group of players. Before players can be added, a game session must have an <code>ACTIVE</code> status, have a creation policy of <code>ALLOW_ALL</code>, and have an open player slot. To add a single player to a game session, use <a>CreatePlayerSession</a>. When a player connects to the game server and references a player session ID, the game server contacts the Amazon GameLift service to validate the player reservation and accept the player.</p> <p>To create player sessions, specify a game session ID, a list of player IDs, and optionally a set of player data strings. If successful, a slot is reserved in the game session for each player and a set of new <a>PlayerSession</a> objects is returned. Player sessions cannot be updated.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var createPlayerSessions* = Call_CreatePlayerSessions_594163(
    name: "createPlayerSessions", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreatePlayerSessions",
    validator: validate_CreatePlayerSessions_594164, base: "/",
    url: url_CreatePlayerSessions_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_594178 = ref object of OpenApiRestCall_593437
proc url_CreateScript_594180(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateScript_594179(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new script record for your Realtime Servers script. Realtime scripts are JavaScript that provide configuration settings and optional custom game logic for your game. The script is deployed when you create a Realtime Servers fleet to host your game sessions. Script logic is executed during an active game session. </p> <p>To create a new script record, specify a script name and provide the script file(s). The script files and all dependencies must be zipped into a single file. You can pull the zip file from either of these locations: </p> <ul> <li> <p>A locally available directory. Use the <i>ZipFile</i> parameter for this option.</p> </li> <li> <p>An Amazon Simple Storage Service (Amazon S3) bucket under your AWS account. Use the <i>StorageLocation</i> parameter for this option. You'll need to have an Identity Access Management (IAM) role that allows the Amazon GameLift service to access your S3 bucket. </p> </li> </ul> <p>If the call is successful, a new script record is created with a unique script ID. If the script file is provided as a local file, the file is uploaded to an Amazon GameLift-owned S3 bucket and the script record's storage location reflects this location. If the script file is provided as an S3 bucket, Amazon GameLift accesses the file at this storage location as needed for deployment.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/setting-up-role.html">Set Up a Role for Amazon GameLift Access</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true,
                                 default = newJString("GameLift.CreateScript"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_CreateScript_594178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new script record for your Realtime Servers script. Realtime scripts are JavaScript that provide configuration settings and optional custom game logic for your game. The script is deployed when you create a Realtime Servers fleet to host your game sessions. Script logic is executed during an active game session. </p> <p>To create a new script record, specify a script name and provide the script file(s). The script files and all dependencies must be zipped into a single file. You can pull the zip file from either of these locations: </p> <ul> <li> <p>A locally available directory. Use the <i>ZipFile</i> parameter for this option.</p> </li> <li> <p>An Amazon Simple Storage Service (Amazon S3) bucket under your AWS account. Use the <i>StorageLocation</i> parameter for this option. You'll need to have an Identity Access Management (IAM) role that allows the Amazon GameLift service to access your S3 bucket. </p> </li> </ul> <p>If the call is successful, a new script record is created with a unique script ID. If the script file is provided as a local file, the file is uploaded to an Amazon GameLift-owned S3 bucket and the script record's storage location reflects this location. If the script file is provided as an S3 bucket, Amazon GameLift accesses the file at this storage location as needed for deployment.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/setting-up-role.html">Set Up a Role for Amazon GameLift Access</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_CreateScript_594178; body: JsonNode): Recallable =
  ## createScript
  ## <p>Creates a new script record for your Realtime Servers script. Realtime scripts are JavaScript that provide configuration settings and optional custom game logic for your game. The script is deployed when you create a Realtime Servers fleet to host your game sessions. Script logic is executed during an active game session. </p> <p>To create a new script record, specify a script name and provide the script file(s). The script files and all dependencies must be zipped into a single file. You can pull the zip file from either of these locations: </p> <ul> <li> <p>A locally available directory. Use the <i>ZipFile</i> parameter for this option.</p> </li> <li> <p>An Amazon Simple Storage Service (Amazon S3) bucket under your AWS account. Use the <i>StorageLocation</i> parameter for this option. You'll need to have an Identity Access Management (IAM) role that allows the Amazon GameLift service to access your S3 bucket. </p> </li> </ul> <p>If the call is successful, a new script record is created with a unique script ID. If the script file is provided as a local file, the file is uploaded to an Amazon GameLift-owned S3 bucket and the script record's storage location reflects this location. If the script file is provided as an S3 bucket, Amazon GameLift accesses the file at this storage location as needed for deployment.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/setting-up-role.html">Set Up a Role for Amazon GameLift Access</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var createScript* = Call_CreateScript_594178(name: "createScript",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreateScript",
    validator: validate_CreateScript_594179, base: "/", url: url_CreateScript_594180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcPeeringAuthorization_594193 = ref object of OpenApiRestCall_593437
proc url_CreateVpcPeeringAuthorization_594195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVpcPeeringAuthorization_594194(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Requests authorization to create or delete a peer connection between the VPC for your Amazon GameLift fleet and a virtual private cloud (VPC) in your AWS account. VPC peering enables the game servers on your fleet to communicate directly with other AWS resources. Once you've received authorization, call <a>CreateVpcPeeringConnection</a> to establish the peering connection. For more information, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html">VPC Peering with Amazon GameLift Fleets</a>.</p> <p>You can peer with VPCs that are owned by any AWS account you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different regions.</p> <p>To request authorization to create a connection, call this operation from the AWS account with the VPC that you want to peer to your Amazon GameLift fleet. For example, to enable your game servers to retrieve data from a DynamoDB table, use the account that manages that DynamoDB resource. Identify the following values: (1) The ID of the VPC that you want to peer with, and (2) the ID of the AWS account that you use to manage Amazon GameLift. If successful, VPC peering is authorized for the specified VPC. </p> <p>To request authorization to delete a connection, call this operation from the AWS account with the VPC that is peered with your Amazon GameLift fleet. Identify the following values: (1) VPC ID that you want to delete the peering connection for, and (2) ID of the AWS account that you use to manage Amazon GameLift. </p> <p>The authorization remains valid for 24 hours unless it is canceled by a call to <a>DeleteVpcPeeringAuthorization</a>. You must create or delete the peering connection while the authorization is valid. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
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
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "GameLift.CreateVpcPeeringAuthorization"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_CreateVpcPeeringAuthorization_594193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests authorization to create or delete a peer connection between the VPC for your Amazon GameLift fleet and a virtual private cloud (VPC) in your AWS account. VPC peering enables the game servers on your fleet to communicate directly with other AWS resources. Once you've received authorization, call <a>CreateVpcPeeringConnection</a> to establish the peering connection. For more information, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html">VPC Peering with Amazon GameLift Fleets</a>.</p> <p>You can peer with VPCs that are owned by any AWS account you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different regions.</p> <p>To request authorization to create a connection, call this operation from the AWS account with the VPC that you want to peer to your Amazon GameLift fleet. For example, to enable your game servers to retrieve data from a DynamoDB table, use the account that manages that DynamoDB resource. Identify the following values: (1) The ID of the VPC that you want to peer with, and (2) the ID of the AWS account that you use to manage Amazon GameLift. If successful, VPC peering is authorized for the specified VPC. </p> <p>To request authorization to delete a connection, call this operation from the AWS account with the VPC that is peered with your Amazon GameLift fleet. Identify the following values: (1) VPC ID that you want to delete the peering connection for, and (2) ID of the AWS account that you use to manage Amazon GameLift. </p> <p>The authorization remains valid for 24 hours unless it is canceled by a call to <a>DeleteVpcPeeringAuthorization</a>. You must create or delete the peering connection while the authorization is valid. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_CreateVpcPeeringAuthorization_594193; body: JsonNode): Recallable =
  ## createVpcPeeringAuthorization
  ## <p>Requests authorization to create or delete a peer connection between the VPC for your Amazon GameLift fleet and a virtual private cloud (VPC) in your AWS account. VPC peering enables the game servers on your fleet to communicate directly with other AWS resources. Once you've received authorization, call <a>CreateVpcPeeringConnection</a> to establish the peering connection. For more information, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html">VPC Peering with Amazon GameLift Fleets</a>.</p> <p>You can peer with VPCs that are owned by any AWS account you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different regions.</p> <p>To request authorization to create a connection, call this operation from the AWS account with the VPC that you want to peer to your Amazon GameLift fleet. For example, to enable your game servers to retrieve data from a DynamoDB table, use the account that manages that DynamoDB resource. Identify the following values: (1) The ID of the VPC that you want to peer with, and (2) the ID of the AWS account that you use to manage Amazon GameLift. If successful, VPC peering is authorized for the specified VPC. </p> <p>To request authorization to delete a connection, call this operation from the AWS account with the VPC that is peered with your Amazon GameLift fleet. Identify the following values: (1) VPC ID that you want to delete the peering connection for, and (2) ID of the AWS account that you use to manage Amazon GameLift. </p> <p>The authorization remains valid for 24 hours unless it is canceled by a call to <a>DeleteVpcPeeringAuthorization</a>. You must create or delete the peering connection while the authorization is valid. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var createVpcPeeringAuthorization* = Call_CreateVpcPeeringAuthorization_594193(
    name: "createVpcPeeringAuthorization", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreateVpcPeeringAuthorization",
    validator: validate_CreateVpcPeeringAuthorization_594194, base: "/",
    url: url_CreateVpcPeeringAuthorization_594195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVpcPeeringConnection_594208 = ref object of OpenApiRestCall_593437
proc url_CreateVpcPeeringConnection_594210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateVpcPeeringConnection_594209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Establishes a VPC peering connection between a virtual private cloud (VPC) in an AWS account with the VPC for your Amazon GameLift fleet. VPC peering enables the game servers on your fleet to communicate directly with other AWS resources. You can peer with VPCs in any AWS account that you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different regions. For more information, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html">VPC Peering with Amazon GameLift Fleets</a>.</p> <p>Before calling this operation to establish the peering connection, you first need to call <a>CreateVpcPeeringAuthorization</a> and identify the VPC you want to peer with. Once the authorization for the specified VPC is issued, you have 24 hours to establish the connection. These two operations handle all tasks necessary to peer the two VPCs, including acceptance, updating routing tables, etc. </p> <p>To establish the connection, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Identify the following values: (1) The ID of the fleet you want to be enable a VPC peering connection for; (2) The AWS account with the VPC that you want to peer with; and (3) The ID of the VPC you want to peer with. This operation is asynchronous. If successful, a <a>VpcPeeringConnection</a> request is created. You can use continuous polling to track the request's status using <a>DescribeVpcPeeringConnections</a>, or by monitoring fleet events for success or failure using <a>DescribeFleetEvents</a>. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
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
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "GameLift.CreateVpcPeeringConnection"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_CreateVpcPeeringConnection_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Establishes a VPC peering connection between a virtual private cloud (VPC) in an AWS account with the VPC for your Amazon GameLift fleet. VPC peering enables the game servers on your fleet to communicate directly with other AWS resources. You can peer with VPCs in any AWS account that you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different regions. For more information, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html">VPC Peering with Amazon GameLift Fleets</a>.</p> <p>Before calling this operation to establish the peering connection, you first need to call <a>CreateVpcPeeringAuthorization</a> and identify the VPC you want to peer with. Once the authorization for the specified VPC is issued, you have 24 hours to establish the connection. These two operations handle all tasks necessary to peer the two VPCs, including acceptance, updating routing tables, etc. </p> <p>To establish the connection, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Identify the following values: (1) The ID of the fleet you want to be enable a VPC peering connection for; (2) The AWS account with the VPC that you want to peer with; and (3) The ID of the VPC you want to peer with. This operation is asynchronous. If successful, a <a>VpcPeeringConnection</a> request is created. You can use continuous polling to track the request's status using <a>DescribeVpcPeeringConnections</a>, or by monitoring fleet events for success or failure using <a>DescribeFleetEvents</a>. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_CreateVpcPeeringConnection_594208; body: JsonNode): Recallable =
  ## createVpcPeeringConnection
  ## <p>Establishes a VPC peering connection between a virtual private cloud (VPC) in an AWS account with the VPC for your Amazon GameLift fleet. VPC peering enables the game servers on your fleet to communicate directly with other AWS resources. You can peer with VPCs in any AWS account that you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different regions. For more information, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html">VPC Peering with Amazon GameLift Fleets</a>.</p> <p>Before calling this operation to establish the peering connection, you first need to call <a>CreateVpcPeeringAuthorization</a> and identify the VPC you want to peer with. Once the authorization for the specified VPC is issued, you have 24 hours to establish the connection. These two operations handle all tasks necessary to peer the two VPCs, including acceptance, updating routing tables, etc. </p> <p>To establish the connection, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Identify the following values: (1) The ID of the fleet you want to be enable a VPC peering connection for; (2) The AWS account with the VPC that you want to peer with; and (3) The ID of the VPC you want to peer with. This operation is asynchronous. If successful, a <a>VpcPeeringConnection</a> request is created. You can use continuous polling to track the request's status using <a>DescribeVpcPeeringConnections</a>, or by monitoring fleet events for success or failure using <a>DescribeFleetEvents</a>. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var createVpcPeeringConnection* = Call_CreateVpcPeeringConnection_594208(
    name: "createVpcPeeringConnection", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.CreateVpcPeeringConnection",
    validator: validate_CreateVpcPeeringConnection_594209, base: "/",
    url: url_CreateVpcPeeringConnection_594210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_594223 = ref object of OpenApiRestCall_593437
proc url_DeleteAlias_594225(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAlias_594224(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an alias. This action removes all record of the alias. Game clients attempting to access a server process using the deleted alias receive an error. To delete an alias, specify the alias ID to be deleted.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
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
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true,
                                 default = newJString("GameLift.DeleteAlias"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_DeleteAlias_594223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an alias. This action removes all record of the alias. Game clients attempting to access a server process using the deleted alias receive an error. To delete an alias, specify the alias ID to be deleted.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_DeleteAlias_594223; body: JsonNode): Recallable =
  ## deleteAlias
  ## <p>Deletes an alias. This action removes all record of the alias. Game clients attempting to access a server process using the deleted alias receive an error. To delete an alias, specify the alias ID to be deleted.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var deleteAlias* = Call_DeleteAlias_594223(name: "deleteAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.DeleteAlias",
                                        validator: validate_DeleteAlias_594224,
                                        base: "/", url: url_DeleteAlias_594225,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBuild_594238 = ref object of OpenApiRestCall_593437
proc url_DeleteBuild_594240(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBuild_594239(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a build. This action permanently deletes the build record and any uploaded build files.</p> <p>To delete a build, specify its ID. Deleting a build does not affect the status of any active fleets using the build, but you can no longer create new fleets with the deleted build.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
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
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594243 = header.getOrDefault("X-Amz-Target")
  valid_594243 = validateParameter(valid_594243, JString, required = true,
                                 default = newJString("GameLift.DeleteBuild"))
  if valid_594243 != nil:
    section.add "X-Amz-Target", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-SignedHeaders", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Credential")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Credential", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_DeleteBuild_594238; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a build. This action permanently deletes the build record and any uploaded build files.</p> <p>To delete a build, specify its ID. Deleting a build does not affect the status of any active fleets using the build, but you can no longer create new fleets with the deleted build.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_DeleteBuild_594238; body: JsonNode): Recallable =
  ## deleteBuild
  ## <p>Deletes a build. This action permanently deletes the build record and any uploaded build files.</p> <p>To delete a build, specify its ID. Deleting a build does not affect the status of any active fleets using the build, but you can no longer create new fleets with the deleted build.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594252 = newJObject()
  if body != nil:
    body_594252 = body
  result = call_594251.call(nil, nil, nil, nil, body_594252)

var deleteBuild* = Call_DeleteBuild_594238(name: "deleteBuild",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.DeleteBuild",
                                        validator: validate_DeleteBuild_594239,
                                        base: "/", url: url_DeleteBuild_594240,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_594253 = ref object of OpenApiRestCall_593437
proc url_DeleteFleet_594255(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFleet_594254(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes everything related to a fleet. Before deleting a fleet, you must set the fleet's desired capacity to zero. See <a>UpdateFleetCapacity</a>.</p> <p>If the fleet being deleted has a VPC peering connection, you first need to get a valid authorization (good for 24 hours) by calling <a>CreateVpcPeeringAuthorization</a>. You do not need to explicitly delete the VPC peering connection--this is done as part of the delete fleet process.</p> <p>This action removes the fleet's resources and the fleet record. Once a fleet is deleted, you can no longer use that fleet.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594258 = header.getOrDefault("X-Amz-Target")
  valid_594258 = validateParameter(valid_594258, JString, required = true,
                                 default = newJString("GameLift.DeleteFleet"))
  if valid_594258 != nil:
    section.add "X-Amz-Target", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_DeleteFleet_594253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes everything related to a fleet. Before deleting a fleet, you must set the fleet's desired capacity to zero. See <a>UpdateFleetCapacity</a>.</p> <p>If the fleet being deleted has a VPC peering connection, you first need to get a valid authorization (good for 24 hours) by calling <a>CreateVpcPeeringAuthorization</a>. You do not need to explicitly delete the VPC peering connection--this is done as part of the delete fleet process.</p> <p>This action removes the fleet's resources and the fleet record. Once a fleet is deleted, you can no longer use that fleet.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_DeleteFleet_594253; body: JsonNode): Recallable =
  ## deleteFleet
  ## <p>Deletes everything related to a fleet. Before deleting a fleet, you must set the fleet's desired capacity to zero. See <a>UpdateFleetCapacity</a>.</p> <p>If the fleet being deleted has a VPC peering connection, you first need to get a valid authorization (good for 24 hours) by calling <a>CreateVpcPeeringAuthorization</a>. You do not need to explicitly delete the VPC peering connection--this is done as part of the delete fleet process.</p> <p>This action removes the fleet's resources and the fleet record. Once a fleet is deleted, you can no longer use that fleet.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var deleteFleet* = Call_DeleteFleet_594253(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.DeleteFleet",
                                        validator: validate_DeleteFleet_594254,
                                        base: "/", url: url_DeleteFleet_594255,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGameSessionQueue_594268 = ref object of OpenApiRestCall_593437
proc url_DeleteGameSessionQueue_594270(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteGameSessionQueue_594269(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a game session queue. This action means that any <a>StartGameSessionPlacement</a> requests that reference this queue will fail. To delete a queue, specify the queue name.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
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
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594273 = header.getOrDefault("X-Amz-Target")
  valid_594273 = validateParameter(valid_594273, JString, required = true, default = newJString(
      "GameLift.DeleteGameSessionQueue"))
  if valid_594273 != nil:
    section.add "X-Amz-Target", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_DeleteGameSessionQueue_594268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a game session queue. This action means that any <a>StartGameSessionPlacement</a> requests that reference this queue will fail. To delete a queue, specify the queue name.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_DeleteGameSessionQueue_594268; body: JsonNode): Recallable =
  ## deleteGameSessionQueue
  ## <p>Deletes a game session queue. This action means that any <a>StartGameSessionPlacement</a> requests that reference this queue will fail. To delete a queue, specify the queue name.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594282 = newJObject()
  if body != nil:
    body_594282 = body
  result = call_594281.call(nil, nil, nil, nil, body_594282)

var deleteGameSessionQueue* = Call_DeleteGameSessionQueue_594268(
    name: "deleteGameSessionQueue", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DeleteGameSessionQueue",
    validator: validate_DeleteGameSessionQueue_594269, base: "/",
    url: url_DeleteGameSessionQueue_594270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMatchmakingConfiguration_594283 = ref object of OpenApiRestCall_593437
proc url_DeleteMatchmakingConfiguration_594285(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMatchmakingConfiguration_594284(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Permanently removes a FlexMatch matchmaking configuration. To delete, specify the configuration name. A matchmaking configuration cannot be deleted if it is being used in any active matchmaking tickets.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594288 = header.getOrDefault("X-Amz-Target")
  valid_594288 = validateParameter(valid_594288, JString, required = true, default = newJString(
      "GameLift.DeleteMatchmakingConfiguration"))
  if valid_594288 != nil:
    section.add "X-Amz-Target", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_DeleteMatchmakingConfiguration_594283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently removes a FlexMatch matchmaking configuration. To delete, specify the configuration name. A matchmaking configuration cannot be deleted if it is being used in any active matchmaking tickets.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_DeleteMatchmakingConfiguration_594283; body: JsonNode): Recallable =
  ## deleteMatchmakingConfiguration
  ## <p>Permanently removes a FlexMatch matchmaking configuration. To delete, specify the configuration name. A matchmaking configuration cannot be deleted if it is being used in any active matchmaking tickets.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594297 = newJObject()
  if body != nil:
    body_594297 = body
  result = call_594296.call(nil, nil, nil, nil, body_594297)

var deleteMatchmakingConfiguration* = Call_DeleteMatchmakingConfiguration_594283(
    name: "deleteMatchmakingConfiguration", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DeleteMatchmakingConfiguration",
    validator: validate_DeleteMatchmakingConfiguration_594284, base: "/",
    url: url_DeleteMatchmakingConfiguration_594285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMatchmakingRuleSet_594298 = ref object of OpenApiRestCall_593437
proc url_DeleteMatchmakingRuleSet_594300(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMatchmakingRuleSet_594299(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an existing matchmaking rule set. To delete the rule set, provide the rule set name. Rule sets cannot be deleted if they are currently being used by a matchmaking configuration. </p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Security-Token")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Security-Token", valid_594302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594303 = header.getOrDefault("X-Amz-Target")
  valid_594303 = validateParameter(valid_594303, JString, required = true, default = newJString(
      "GameLift.DeleteMatchmakingRuleSet"))
  if valid_594303 != nil:
    section.add "X-Amz-Target", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_DeleteMatchmakingRuleSet_594298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing matchmaking rule set. To delete the rule set, provide the rule set name. Rule sets cannot be deleted if they are currently being used by a matchmaking configuration. </p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_DeleteMatchmakingRuleSet_594298; body: JsonNode): Recallable =
  ## deleteMatchmakingRuleSet
  ## <p>Deletes an existing matchmaking rule set. To delete the rule set, provide the rule set name. Rule sets cannot be deleted if they are currently being used by a matchmaking configuration. </p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594312 = newJObject()
  if body != nil:
    body_594312 = body
  result = call_594311.call(nil, nil, nil, nil, body_594312)

var deleteMatchmakingRuleSet* = Call_DeleteMatchmakingRuleSet_594298(
    name: "deleteMatchmakingRuleSet", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DeleteMatchmakingRuleSet",
    validator: validate_DeleteMatchmakingRuleSet_594299, base: "/",
    url: url_DeleteMatchmakingRuleSet_594300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteScalingPolicy_594313 = ref object of OpenApiRestCall_593437
proc url_DeleteScalingPolicy_594315(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteScalingPolicy_594314(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes a fleet scaling policy. This action means that the policy is no longer in force and removes all record of it. To delete a scaling policy, specify both the scaling policy name and the fleet ID it is associated with.</p> <p>To temporarily suspend scaling policies, call <a>StopFleetActions</a>. This operation suspends all policies for the fleet.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Security-Token")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Security-Token", valid_594317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594318 = header.getOrDefault("X-Amz-Target")
  valid_594318 = validateParameter(valid_594318, JString, required = true, default = newJString(
      "GameLift.DeleteScalingPolicy"))
  if valid_594318 != nil:
    section.add "X-Amz-Target", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Content-Sha256", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Signature")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Signature", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Credential")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Credential", valid_594323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_DeleteScalingPolicy_594313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a fleet scaling policy. This action means that the policy is no longer in force and removes all record of it. To delete a scaling policy, specify both the scaling policy name and the fleet ID it is associated with.</p> <p>To temporarily suspend scaling policies, call <a>StopFleetActions</a>. This operation suspends all policies for the fleet.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_DeleteScalingPolicy_594313; body: JsonNode): Recallable =
  ## deleteScalingPolicy
  ## <p>Deletes a fleet scaling policy. This action means that the policy is no longer in force and removes all record of it. To delete a scaling policy, specify both the scaling policy name and the fleet ID it is associated with.</p> <p>To temporarily suspend scaling policies, call <a>StopFleetActions</a>. This operation suspends all policies for the fleet.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594327 = newJObject()
  if body != nil:
    body_594327 = body
  result = call_594326.call(nil, nil, nil, nil, body_594327)

var deleteScalingPolicy* = Call_DeleteScalingPolicy_594313(
    name: "deleteScalingPolicy", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DeleteScalingPolicy",
    validator: validate_DeleteScalingPolicy_594314, base: "/",
    url: url_DeleteScalingPolicy_594315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteScript_594328 = ref object of OpenApiRestCall_593437
proc url_DeleteScript_594330(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteScript_594329(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a Realtime script. This action permanently deletes the script record. If script files were uploaded, they are also deleted (files stored in an S3 bucket are not deleted). </p> <p>To delete a script, specify the script ID. Before deleting a script, be sure to terminate all fleets that are deployed with the script being deleted. Fleet instances periodically check for script updates, and if the script record no longer exists, the instance will go into an error state and be unable to host game sessions.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
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
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594333 = header.getOrDefault("X-Amz-Target")
  valid_594333 = validateParameter(valid_594333, JString, required = true,
                                 default = newJString("GameLift.DeleteScript"))
  if valid_594333 != nil:
    section.add "X-Amz-Target", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Content-Sha256", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Algorithm")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Algorithm", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Signature")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Signature", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Credential")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Credential", valid_594338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_DeleteScript_594328; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Realtime script. This action permanently deletes the script record. If script files were uploaded, they are also deleted (files stored in an S3 bucket are not deleted). </p> <p>To delete a script, specify the script ID. Before deleting a script, be sure to terminate all fleets that are deployed with the script being deleted. Fleet instances periodically check for script updates, and if the script record no longer exists, the instance will go into an error state and be unable to host game sessions.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_DeleteScript_594328; body: JsonNode): Recallable =
  ## deleteScript
  ## <p>Deletes a Realtime script. This action permanently deletes the script record. If script files were uploaded, they are also deleted (files stored in an S3 bucket are not deleted). </p> <p>To delete a script, specify the script ID. Before deleting a script, be sure to terminate all fleets that are deployed with the script being deleted. Fleet instances periodically check for script updates, and if the script record no longer exists, the instance will go into an error state and be unable to host game sessions.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594342 = newJObject()
  if body != nil:
    body_594342 = body
  result = call_594341.call(nil, nil, nil, nil, body_594342)

var deleteScript* = Call_DeleteScript_594328(name: "deleteScript",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DeleteScript",
    validator: validate_DeleteScript_594329, base: "/", url: url_DeleteScript_594330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcPeeringAuthorization_594343 = ref object of OpenApiRestCall_593437
proc url_DeleteVpcPeeringAuthorization_594345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteVpcPeeringAuthorization_594344(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Cancels a pending VPC peering authorization for the specified VPC. If you need to delete an existing VPC peering connection, call <a>DeleteVpcPeeringConnection</a>. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
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
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594348 = header.getOrDefault("X-Amz-Target")
  valid_594348 = validateParameter(valid_594348, JString, required = true, default = newJString(
      "GameLift.DeleteVpcPeeringAuthorization"))
  if valid_594348 != nil:
    section.add "X-Amz-Target", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_DeleteVpcPeeringAuthorization_594343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a pending VPC peering authorization for the specified VPC. If you need to delete an existing VPC peering connection, call <a>DeleteVpcPeeringConnection</a>. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_DeleteVpcPeeringAuthorization_594343; body: JsonNode): Recallable =
  ## deleteVpcPeeringAuthorization
  ## <p>Cancels a pending VPC peering authorization for the specified VPC. If you need to delete an existing VPC peering connection, call <a>DeleteVpcPeeringConnection</a>. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594357 = newJObject()
  if body != nil:
    body_594357 = body
  result = call_594356.call(nil, nil, nil, nil, body_594357)

var deleteVpcPeeringAuthorization* = Call_DeleteVpcPeeringAuthorization_594343(
    name: "deleteVpcPeeringAuthorization", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DeleteVpcPeeringAuthorization",
    validator: validate_DeleteVpcPeeringAuthorization_594344, base: "/",
    url: url_DeleteVpcPeeringAuthorization_594345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVpcPeeringConnection_594358 = ref object of OpenApiRestCall_593437
proc url_DeleteVpcPeeringConnection_594360(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteVpcPeeringConnection_594359(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a VPC peering connection. To delete the connection, you must have a valid authorization for the VPC peering connection that you want to delete. You can check for an authorization by calling <a>DescribeVpcPeeringAuthorizations</a> or request a new one using <a>CreateVpcPeeringAuthorization</a>. </p> <p>Once a valid authorization exists, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Identify the connection to delete by the connection ID and fleet ID. If successful, the connection is removed. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
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
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Security-Token")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Security-Token", valid_594362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594363 = header.getOrDefault("X-Amz-Target")
  valid_594363 = validateParameter(valid_594363, JString, required = true, default = newJString(
      "GameLift.DeleteVpcPeeringConnection"))
  if valid_594363 != nil:
    section.add "X-Amz-Target", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Signature")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Signature", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Credential")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Credential", valid_594368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_DeleteVpcPeeringConnection_594358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a VPC peering connection. To delete the connection, you must have a valid authorization for the VPC peering connection that you want to delete. You can check for an authorization by calling <a>DescribeVpcPeeringAuthorizations</a> or request a new one using <a>CreateVpcPeeringAuthorization</a>. </p> <p>Once a valid authorization exists, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Identify the connection to delete by the connection ID and fleet ID. If successful, the connection is removed. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_DeleteVpcPeeringConnection_594358; body: JsonNode): Recallable =
  ## deleteVpcPeeringConnection
  ## <p>Removes a VPC peering connection. To delete the connection, you must have a valid authorization for the VPC peering connection that you want to delete. You can check for an authorization by calling <a>DescribeVpcPeeringAuthorizations</a> or request a new one using <a>CreateVpcPeeringAuthorization</a>. </p> <p>Once a valid authorization exists, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Identify the connection to delete by the connection ID and fleet ID. If successful, the connection is removed. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594372 = newJObject()
  if body != nil:
    body_594372 = body
  result = call_594371.call(nil, nil, nil, nil, body_594372)

var deleteVpcPeeringConnection* = Call_DeleteVpcPeeringConnection_594358(
    name: "deleteVpcPeeringConnection", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DeleteVpcPeeringConnection",
    validator: validate_DeleteVpcPeeringConnection_594359, base: "/",
    url: url_DeleteVpcPeeringConnection_594360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlias_594373 = ref object of OpenApiRestCall_593437
proc url_DescribeAlias_594375(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAlias_594374(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves properties for an alias. This operation returns all alias metadata and settings. To get an alias's target fleet ID only, use <code>ResolveAlias</code>. </p> <p>To get alias properties, specify the alias ID. If successful, the requested alias record is returned.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
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
  var valid_594376 = header.getOrDefault("X-Amz-Date")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Date", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Security-Token")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Security-Token", valid_594377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594378 = header.getOrDefault("X-Amz-Target")
  valid_594378 = validateParameter(valid_594378, JString, required = true,
                                 default = newJString("GameLift.DescribeAlias"))
  if valid_594378 != nil:
    section.add "X-Amz-Target", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594385: Call_DescribeAlias_594373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves properties for an alias. This operation returns all alias metadata and settings. To get an alias's target fleet ID only, use <code>ResolveAlias</code>. </p> <p>To get alias properties, specify the alias ID. If successful, the requested alias record is returned.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ## 
  let valid = call_594385.validator(path, query, header, formData, body)
  let scheme = call_594385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594385.url(scheme.get, call_594385.host, call_594385.base,
                         call_594385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594385, url, valid)

proc call*(call_594386: Call_DescribeAlias_594373; body: JsonNode): Recallable =
  ## describeAlias
  ## <p>Retrieves properties for an alias. This operation returns all alias metadata and settings. To get an alias's target fleet ID only, use <code>ResolveAlias</code>. </p> <p>To get alias properties, specify the alias ID. If successful, the requested alias record is returned.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594387 = newJObject()
  if body != nil:
    body_594387 = body
  result = call_594386.call(nil, nil, nil, nil, body_594387)

var describeAlias* = Call_DescribeAlias_594373(name: "describeAlias",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeAlias",
    validator: validate_DescribeAlias_594374, base: "/", url: url_DescribeAlias_594375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBuild_594388 = ref object of OpenApiRestCall_593437
proc url_DescribeBuild_594390(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBuild_594389(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves properties for a build. To request a build record, specify a build ID. If successful, an object containing the build properties is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
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
  var valid_594391 = header.getOrDefault("X-Amz-Date")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Date", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Security-Token")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Security-Token", valid_594392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594393 = header.getOrDefault("X-Amz-Target")
  valid_594393 = validateParameter(valid_594393, JString, required = true,
                                 default = newJString("GameLift.DescribeBuild"))
  if valid_594393 != nil:
    section.add "X-Amz-Target", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Content-Sha256", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Algorithm")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Algorithm", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Signature")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Signature", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-SignedHeaders", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Credential")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Credential", valid_594398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594400: Call_DescribeBuild_594388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves properties for a build. To request a build record, specify a build ID. If successful, an object containing the build properties is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ## 
  let valid = call_594400.validator(path, query, header, formData, body)
  let scheme = call_594400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594400.url(scheme.get, call_594400.host, call_594400.base,
                         call_594400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594400, url, valid)

proc call*(call_594401: Call_DescribeBuild_594388; body: JsonNode): Recallable =
  ## describeBuild
  ## <p>Retrieves properties for a build. To request a build record, specify a build ID. If successful, an object containing the build properties is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594402 = newJObject()
  if body != nil:
    body_594402 = body
  result = call_594401.call(nil, nil, nil, nil, body_594402)

var describeBuild* = Call_DescribeBuild_594388(name: "describeBuild",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeBuild",
    validator: validate_DescribeBuild_594389, base: "/", url: url_DescribeBuild_594390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEC2InstanceLimits_594403 = ref object of OpenApiRestCall_593437
proc url_DescribeEC2InstanceLimits_594405(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEC2InstanceLimits_594404(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the following information for the specified EC2 instance type:</p> <ul> <li> <p>maximum number of instances allowed per AWS account (service limit)</p> </li> <li> <p>current usage level for the AWS account</p> </li> </ul> <p>Service limits vary depending on region. Available regions for Amazon GameLift can be found in the AWS Management Console for Amazon GameLift (see the drop-down list in the upper right corner).</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594406 = header.getOrDefault("X-Amz-Date")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Date", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Security-Token")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Security-Token", valid_594407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594408 = header.getOrDefault("X-Amz-Target")
  valid_594408 = validateParameter(valid_594408, JString, required = true, default = newJString(
      "GameLift.DescribeEC2InstanceLimits"))
  if valid_594408 != nil:
    section.add "X-Amz-Target", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Content-Sha256", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Algorithm")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Algorithm", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Signature")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Signature", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-SignedHeaders", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Credential")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Credential", valid_594413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594415: Call_DescribeEC2InstanceLimits_594403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the following information for the specified EC2 instance type:</p> <ul> <li> <p>maximum number of instances allowed per AWS account (service limit)</p> </li> <li> <p>current usage level for the AWS account</p> </li> </ul> <p>Service limits vary depending on region. Available regions for Amazon GameLift can be found in the AWS Management Console for Amazon GameLift (see the drop-down list in the upper right corner).</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594415.validator(path, query, header, formData, body)
  let scheme = call_594415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594415.url(scheme.get, call_594415.host, call_594415.base,
                         call_594415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594415, url, valid)

proc call*(call_594416: Call_DescribeEC2InstanceLimits_594403; body: JsonNode): Recallable =
  ## describeEC2InstanceLimits
  ## <p>Retrieves the following information for the specified EC2 instance type:</p> <ul> <li> <p>maximum number of instances allowed per AWS account (service limit)</p> </li> <li> <p>current usage level for the AWS account</p> </li> </ul> <p>Service limits vary depending on region. Available regions for Amazon GameLift can be found in the AWS Management Console for Amazon GameLift (see the drop-down list in the upper right corner).</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594417 = newJObject()
  if body != nil:
    body_594417 = body
  result = call_594416.call(nil, nil, nil, nil, body_594417)

var describeEC2InstanceLimits* = Call_DescribeEC2InstanceLimits_594403(
    name: "describeEC2InstanceLimits", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeEC2InstanceLimits",
    validator: validate_DescribeEC2InstanceLimits_594404, base: "/",
    url: url_DescribeEC2InstanceLimits_594405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetAttributes_594418 = ref object of OpenApiRestCall_593437
proc url_DescribeFleetAttributes_594420(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleetAttributes_594419(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves fleet properties, including metadata, status, and configuration, for one or more fleets. You can request attributes for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetAttributes</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, attribute objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594421 = header.getOrDefault("X-Amz-Date")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Date", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Security-Token")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Security-Token", valid_594422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594423 = header.getOrDefault("X-Amz-Target")
  valid_594423 = validateParameter(valid_594423, JString, required = true, default = newJString(
      "GameLift.DescribeFleetAttributes"))
  if valid_594423 != nil:
    section.add "X-Amz-Target", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Content-Sha256", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Algorithm")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Algorithm", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-SignedHeaders", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Credential")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Credential", valid_594428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594430: Call_DescribeFleetAttributes_594418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves fleet properties, including metadata, status, and configuration, for one or more fleets. You can request attributes for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetAttributes</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, attribute objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594430.validator(path, query, header, formData, body)
  let scheme = call_594430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594430.url(scheme.get, call_594430.host, call_594430.base,
                         call_594430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594430, url, valid)

proc call*(call_594431: Call_DescribeFleetAttributes_594418; body: JsonNode): Recallable =
  ## describeFleetAttributes
  ## <p>Retrieves fleet properties, including metadata, status, and configuration, for one or more fleets. You can request attributes for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetAttributes</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, attribute objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594432 = newJObject()
  if body != nil:
    body_594432 = body
  result = call_594431.call(nil, nil, nil, nil, body_594432)

var describeFleetAttributes* = Call_DescribeFleetAttributes_594418(
    name: "describeFleetAttributes", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeFleetAttributes",
    validator: validate_DescribeFleetAttributes_594419, base: "/",
    url: url_DescribeFleetAttributes_594420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetCapacity_594433 = ref object of OpenApiRestCall_593437
proc url_DescribeFleetCapacity_594435(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleetCapacity_594434(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the current status of fleet capacity for one or more fleets. This information includes the number of instances that have been requested for the fleet and the number currently active. You can request capacity for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetCapacity</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, attribute objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594436 = header.getOrDefault("X-Amz-Date")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Date", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Security-Token")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Security-Token", valid_594437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594438 = header.getOrDefault("X-Amz-Target")
  valid_594438 = validateParameter(valid_594438, JString, required = true, default = newJString(
      "GameLift.DescribeFleetCapacity"))
  if valid_594438 != nil:
    section.add "X-Amz-Target", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Content-Sha256", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Algorithm")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Algorithm", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Signature")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Signature", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-SignedHeaders", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Credential")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Credential", valid_594443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594445: Call_DescribeFleetCapacity_594433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the current status of fleet capacity for one or more fleets. This information includes the number of instances that have been requested for the fleet and the number currently active. You can request capacity for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetCapacity</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, attribute objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594445.validator(path, query, header, formData, body)
  let scheme = call_594445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594445.url(scheme.get, call_594445.host, call_594445.base,
                         call_594445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594445, url, valid)

proc call*(call_594446: Call_DescribeFleetCapacity_594433; body: JsonNode): Recallable =
  ## describeFleetCapacity
  ## <p>Retrieves the current status of fleet capacity for one or more fleets. This information includes the number of instances that have been requested for the fleet and the number currently active. You can request capacity for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetCapacity</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, attribute objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594447 = newJObject()
  if body != nil:
    body_594447 = body
  result = call_594446.call(nil, nil, nil, nil, body_594447)

var describeFleetCapacity* = Call_DescribeFleetCapacity_594433(
    name: "describeFleetCapacity", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeFleetCapacity",
    validator: validate_DescribeFleetCapacity_594434, base: "/",
    url: url_DescribeFleetCapacity_594435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetEvents_594448 = ref object of OpenApiRestCall_593437
proc url_DescribeFleetEvents_594450(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleetEvents_594449(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieves entries from the specified fleet's event log. You can specify a time range to limit the result set. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a collection of event log entries matching the request are returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594451 = header.getOrDefault("X-Amz-Date")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Date", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Security-Token")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Security-Token", valid_594452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594453 = header.getOrDefault("X-Amz-Target")
  valid_594453 = validateParameter(valid_594453, JString, required = true, default = newJString(
      "GameLift.DescribeFleetEvents"))
  if valid_594453 != nil:
    section.add "X-Amz-Target", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Content-Sha256", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Algorithm")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Algorithm", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Signature")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Signature", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-SignedHeaders", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Credential")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Credential", valid_594458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594460: Call_DescribeFleetEvents_594448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves entries from the specified fleet's event log. You can specify a time range to limit the result set. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a collection of event log entries matching the request are returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594460.validator(path, query, header, formData, body)
  let scheme = call_594460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594460.url(scheme.get, call_594460.host, call_594460.base,
                         call_594460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594460, url, valid)

proc call*(call_594461: Call_DescribeFleetEvents_594448; body: JsonNode): Recallable =
  ## describeFleetEvents
  ## <p>Retrieves entries from the specified fleet's event log. You can specify a time range to limit the result set. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a collection of event log entries matching the request are returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594462 = newJObject()
  if body != nil:
    body_594462 = body
  result = call_594461.call(nil, nil, nil, nil, body_594462)

var describeFleetEvents* = Call_DescribeFleetEvents_594448(
    name: "describeFleetEvents", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeFleetEvents",
    validator: validate_DescribeFleetEvents_594449, base: "/",
    url: url_DescribeFleetEvents_594450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetPortSettings_594463 = ref object of OpenApiRestCall_593437
proc url_DescribeFleetPortSettings_594465(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleetPortSettings_594464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the inbound connection permissions for a fleet. Connection permissions include a range of IP addresses and port settings that incoming traffic can use to access server processes in the fleet. To get a fleet's inbound connection permissions, specify a fleet ID. If successful, a collection of <a>IpPermission</a> objects is returned for the requested fleet ID. If the requested fleet has been deleted, the result set is empty.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594466 = header.getOrDefault("X-Amz-Date")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Date", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Security-Token")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Security-Token", valid_594467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594468 = header.getOrDefault("X-Amz-Target")
  valid_594468 = validateParameter(valid_594468, JString, required = true, default = newJString(
      "GameLift.DescribeFleetPortSettings"))
  if valid_594468 != nil:
    section.add "X-Amz-Target", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Content-Sha256", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Algorithm")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Algorithm", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Signature")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Signature", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-SignedHeaders", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Credential")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Credential", valid_594473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_DescribeFleetPortSettings_594463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the inbound connection permissions for a fleet. Connection permissions include a range of IP addresses and port settings that incoming traffic can use to access server processes in the fleet. To get a fleet's inbound connection permissions, specify a fleet ID. If successful, a collection of <a>IpPermission</a> objects is returned for the requested fleet ID. If the requested fleet has been deleted, the result set is empty.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_DescribeFleetPortSettings_594463; body: JsonNode): Recallable =
  ## describeFleetPortSettings
  ## <p>Retrieves the inbound connection permissions for a fleet. Connection permissions include a range of IP addresses and port settings that incoming traffic can use to access server processes in the fleet. To get a fleet's inbound connection permissions, specify a fleet ID. If successful, a collection of <a>IpPermission</a> objects is returned for the requested fleet ID. If the requested fleet has been deleted, the result set is empty.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594477 = newJObject()
  if body != nil:
    body_594477 = body
  result = call_594476.call(nil, nil, nil, nil, body_594477)

var describeFleetPortSettings* = Call_DescribeFleetPortSettings_594463(
    name: "describeFleetPortSettings", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeFleetPortSettings",
    validator: validate_DescribeFleetPortSettings_594464, base: "/",
    url: url_DescribeFleetPortSettings_594465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleetUtilization_594478 = ref object of OpenApiRestCall_593437
proc url_DescribeFleetUtilization_594480(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleetUtilization_594479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves utilization statistics for one or more fleets. You can request utilization data for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetUtilization</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, utilization objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594481 = header.getOrDefault("X-Amz-Date")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Date", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Security-Token")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Security-Token", valid_594482
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594483 = header.getOrDefault("X-Amz-Target")
  valid_594483 = validateParameter(valid_594483, JString, required = true, default = newJString(
      "GameLift.DescribeFleetUtilization"))
  if valid_594483 != nil:
    section.add "X-Amz-Target", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Content-Sha256", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Algorithm")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Algorithm", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Signature")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Signature", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-SignedHeaders", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Credential")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Credential", valid_594488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594490: Call_DescribeFleetUtilization_594478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves utilization statistics for one or more fleets. You can request utilization data for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetUtilization</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, utilization objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594490.validator(path, query, header, formData, body)
  let scheme = call_594490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594490.url(scheme.get, call_594490.host, call_594490.base,
                         call_594490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594490, url, valid)

proc call*(call_594491: Call_DescribeFleetUtilization_594478; body: JsonNode): Recallable =
  ## describeFleetUtilization
  ## <p>Retrieves utilization statistics for one or more fleets. You can request utilization data for all fleets, or specify a list of one or more fleet IDs. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>FleetUtilization</a> object is returned for each requested fleet ID. When specifying a list of fleet IDs, utilization objects are returned only for fleets that currently exist. </p> <note> <p>Some API actions may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594492 = newJObject()
  if body != nil:
    body_594492 = body
  result = call_594491.call(nil, nil, nil, nil, body_594492)

var describeFleetUtilization* = Call_DescribeFleetUtilization_594478(
    name: "describeFleetUtilization", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeFleetUtilization",
    validator: validate_DescribeFleetUtilization_594479, base: "/",
    url: url_DescribeFleetUtilization_594480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGameSessionDetails_594493 = ref object of OpenApiRestCall_593437
proc url_DescribeGameSessionDetails_594495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGameSessionDetails_594494(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves properties, including the protection policy in force, for one or more game sessions. This action can be used in several ways: (1) provide a <code>GameSessionId</code> or <code>GameSessionArn</code> to request details for a specific game session; (2) provide either a <code>FleetId</code> or an <code>AliasId</code> to request properties for all game sessions running on a fleet. </p> <p>To get game session record(s), specify just one of the following: game session ID, fleet ID, or alias ID. You can filter this request by game session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSessionDetail</a> object is returned for each session matching the request.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594496 = header.getOrDefault("X-Amz-Date")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Date", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Security-Token")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Security-Token", valid_594497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594498 = header.getOrDefault("X-Amz-Target")
  valid_594498 = validateParameter(valid_594498, JString, required = true, default = newJString(
      "GameLift.DescribeGameSessionDetails"))
  if valid_594498 != nil:
    section.add "X-Amz-Target", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Content-Sha256", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Algorithm")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Algorithm", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Signature")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Signature", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-SignedHeaders", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Credential")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Credential", valid_594503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594505: Call_DescribeGameSessionDetails_594493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves properties, including the protection policy in force, for one or more game sessions. This action can be used in several ways: (1) provide a <code>GameSessionId</code> or <code>GameSessionArn</code> to request details for a specific game session; (2) provide either a <code>FleetId</code> or an <code>AliasId</code> to request properties for all game sessions running on a fleet. </p> <p>To get game session record(s), specify just one of the following: game session ID, fleet ID, or alias ID. You can filter this request by game session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSessionDetail</a> object is returned for each session matching the request.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594505.validator(path, query, header, formData, body)
  let scheme = call_594505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594505.url(scheme.get, call_594505.host, call_594505.base,
                         call_594505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594505, url, valid)

proc call*(call_594506: Call_DescribeGameSessionDetails_594493; body: JsonNode): Recallable =
  ## describeGameSessionDetails
  ## <p>Retrieves properties, including the protection policy in force, for one or more game sessions. This action can be used in several ways: (1) provide a <code>GameSessionId</code> or <code>GameSessionArn</code> to request details for a specific game session; (2) provide either a <code>FleetId</code> or an <code>AliasId</code> to request properties for all game sessions running on a fleet. </p> <p>To get game session record(s), specify just one of the following: game session ID, fleet ID, or alias ID. You can filter this request by game session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSessionDetail</a> object is returned for each session matching the request.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594507 = newJObject()
  if body != nil:
    body_594507 = body
  result = call_594506.call(nil, nil, nil, nil, body_594507)

var describeGameSessionDetails* = Call_DescribeGameSessionDetails_594493(
    name: "describeGameSessionDetails", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeGameSessionDetails",
    validator: validate_DescribeGameSessionDetails_594494, base: "/",
    url: url_DescribeGameSessionDetails_594495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGameSessionPlacement_594508 = ref object of OpenApiRestCall_593437
proc url_DescribeGameSessionPlacement_594510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGameSessionPlacement_594509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves properties and current status of a game session placement request. To get game session placement details, specify the placement ID. If successful, a <a>GameSessionPlacement</a> object is returned.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594511 = header.getOrDefault("X-Amz-Date")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Date", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Security-Token")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Security-Token", valid_594512
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594513 = header.getOrDefault("X-Amz-Target")
  valid_594513 = validateParameter(valid_594513, JString, required = true, default = newJString(
      "GameLift.DescribeGameSessionPlacement"))
  if valid_594513 != nil:
    section.add "X-Amz-Target", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Content-Sha256", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Algorithm")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Algorithm", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Signature")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Signature", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-SignedHeaders", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Credential")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Credential", valid_594518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594520: Call_DescribeGameSessionPlacement_594508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves properties and current status of a game session placement request. To get game session placement details, specify the placement ID. If successful, a <a>GameSessionPlacement</a> object is returned.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594520.validator(path, query, header, formData, body)
  let scheme = call_594520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594520.url(scheme.get, call_594520.host, call_594520.base,
                         call_594520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594520, url, valid)

proc call*(call_594521: Call_DescribeGameSessionPlacement_594508; body: JsonNode): Recallable =
  ## describeGameSessionPlacement
  ## <p>Retrieves properties and current status of a game session placement request. To get game session placement details, specify the placement ID. If successful, a <a>GameSessionPlacement</a> object is returned.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594522 = newJObject()
  if body != nil:
    body_594522 = body
  result = call_594521.call(nil, nil, nil, nil, body_594522)

var describeGameSessionPlacement* = Call_DescribeGameSessionPlacement_594508(
    name: "describeGameSessionPlacement", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeGameSessionPlacement",
    validator: validate_DescribeGameSessionPlacement_594509, base: "/",
    url: url_DescribeGameSessionPlacement_594510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGameSessionQueues_594523 = ref object of OpenApiRestCall_593437
proc url_DescribeGameSessionQueues_594525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGameSessionQueues_594524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the properties for one or more game session queues. When requesting multiple queues, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSessionQueue</a> object is returned for each requested queue. When specifying a list of queues, objects are returned only for queues that currently exist in the region.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
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
  var valid_594526 = header.getOrDefault("X-Amz-Date")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Date", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Security-Token")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Security-Token", valid_594527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594528 = header.getOrDefault("X-Amz-Target")
  valid_594528 = validateParameter(valid_594528, JString, required = true, default = newJString(
      "GameLift.DescribeGameSessionQueues"))
  if valid_594528 != nil:
    section.add "X-Amz-Target", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Content-Sha256", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Algorithm")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Algorithm", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-SignedHeaders", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Credential")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Credential", valid_594533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594535: Call_DescribeGameSessionQueues_594523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the properties for one or more game session queues. When requesting multiple queues, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSessionQueue</a> object is returned for each requested queue. When specifying a list of queues, objects are returned only for queues that currently exist in the region.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ## 
  let valid = call_594535.validator(path, query, header, formData, body)
  let scheme = call_594535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594535.url(scheme.get, call_594535.host, call_594535.base,
                         call_594535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594535, url, valid)

proc call*(call_594536: Call_DescribeGameSessionQueues_594523; body: JsonNode): Recallable =
  ## describeGameSessionQueues
  ## <p>Retrieves the properties for one or more game session queues. When requesting multiple queues, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSessionQueue</a> object is returned for each requested queue. When specifying a list of queues, objects are returned only for queues that currently exist in the region.</p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594537 = newJObject()
  if body != nil:
    body_594537 = body
  result = call_594536.call(nil, nil, nil, nil, body_594537)

var describeGameSessionQueues* = Call_DescribeGameSessionQueues_594523(
    name: "describeGameSessionQueues", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeGameSessionQueues",
    validator: validate_DescribeGameSessionQueues_594524, base: "/",
    url: url_DescribeGameSessionQueues_594525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGameSessions_594538 = ref object of OpenApiRestCall_593437
proc url_DescribeGameSessions_594540(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeGameSessions_594539(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a set of one or more game sessions. Request a specific game session or request all game sessions on a fleet. Alternatively, use <a>SearchGameSessions</a> to request a set of active game sessions that are filtered by certain criteria. To retrieve protection policy settings for game sessions, use <a>DescribeGameSessionDetails</a>.</p> <p>To get game sessions, specify one of the following: game session ID, fleet ID, or alias ID. You can filter this request by game session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSession</a> object is returned for each game session matching the request.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594541 = header.getOrDefault("X-Amz-Date")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Date", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Security-Token")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Security-Token", valid_594542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594543 = header.getOrDefault("X-Amz-Target")
  valid_594543 = validateParameter(valid_594543, JString, required = true, default = newJString(
      "GameLift.DescribeGameSessions"))
  if valid_594543 != nil:
    section.add "X-Amz-Target", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Content-Sha256", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-Algorithm")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Algorithm", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Signature")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Signature", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-SignedHeaders", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Credential")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Credential", valid_594548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594550: Call_DescribeGameSessions_594538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a set of one or more game sessions. Request a specific game session or request all game sessions on a fleet. Alternatively, use <a>SearchGameSessions</a> to request a set of active game sessions that are filtered by certain criteria. To retrieve protection policy settings for game sessions, use <a>DescribeGameSessionDetails</a>.</p> <p>To get game sessions, specify one of the following: game session ID, fleet ID, or alias ID. You can filter this request by game session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSession</a> object is returned for each game session matching the request.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594550.validator(path, query, header, formData, body)
  let scheme = call_594550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594550.url(scheme.get, call_594550.host, call_594550.base,
                         call_594550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594550, url, valid)

proc call*(call_594551: Call_DescribeGameSessions_594538; body: JsonNode): Recallable =
  ## describeGameSessions
  ## <p>Retrieves a set of one or more game sessions. Request a specific game session or request all game sessions on a fleet. Alternatively, use <a>SearchGameSessions</a> to request a set of active game sessions that are filtered by certain criteria. To retrieve protection policy settings for game sessions, use <a>DescribeGameSessionDetails</a>.</p> <p>To get game sessions, specify one of the following: game session ID, fleet ID, or alias ID. You can filter this request by game session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>GameSession</a> object is returned for each game session matching the request.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594552 = newJObject()
  if body != nil:
    body_594552 = body
  result = call_594551.call(nil, nil, nil, nil, body_594552)

var describeGameSessions* = Call_DescribeGameSessions_594538(
    name: "describeGameSessions", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeGameSessions",
    validator: validate_DescribeGameSessions_594539, base: "/",
    url: url_DescribeGameSessions_594540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstances_594553 = ref object of OpenApiRestCall_593437
proc url_DescribeInstances_594555(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeInstances_594554(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves information about a fleet's instances, including instance IDs. Use this action to get details on all instances in the fleet or get details on one specific instance.</p> <p>To get a specific instance, specify fleet ID and instance ID. To get all instances in a fleet, specify a fleet ID only. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, an <a>Instance</a> object is returned for each result.</p>
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
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Security-Token")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Security-Token", valid_594557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594558 = header.getOrDefault("X-Amz-Target")
  valid_594558 = validateParameter(valid_594558, JString, required = true, default = newJString(
      "GameLift.DescribeInstances"))
  if valid_594558 != nil:
    section.add "X-Amz-Target", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Content-Sha256", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Algorithm")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Algorithm", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Signature")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Signature", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-SignedHeaders", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Credential")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Credential", valid_594563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594565: Call_DescribeInstances_594553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a fleet's instances, including instance IDs. Use this action to get details on all instances in the fleet or get details on one specific instance.</p> <p>To get a specific instance, specify fleet ID and instance ID. To get all instances in a fleet, specify a fleet ID only. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, an <a>Instance</a> object is returned for each result.</p>
  ## 
  let valid = call_594565.validator(path, query, header, formData, body)
  let scheme = call_594565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594565.url(scheme.get, call_594565.host, call_594565.base,
                         call_594565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594565, url, valid)

proc call*(call_594566: Call_DescribeInstances_594553; body: JsonNode): Recallable =
  ## describeInstances
  ## <p>Retrieves information about a fleet's instances, including instance IDs. Use this action to get details on all instances in the fleet or get details on one specific instance.</p> <p>To get a specific instance, specify fleet ID and instance ID. To get all instances in a fleet, specify a fleet ID only. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, an <a>Instance</a> object is returned for each result.</p>
  ##   body: JObject (required)
  var body_594567 = newJObject()
  if body != nil:
    body_594567 = body
  result = call_594566.call(nil, nil, nil, nil, body_594567)

var describeInstances* = Call_DescribeInstances_594553(name: "describeInstances",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeInstances",
    validator: validate_DescribeInstances_594554, base: "/",
    url: url_DescribeInstances_594555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMatchmaking_594568 = ref object of OpenApiRestCall_593437
proc url_DescribeMatchmaking_594570(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMatchmaking_594569(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieves one or more matchmaking tickets. Use this operation to retrieve ticket information, including status and--once a successful match is made--acquire connection information for the resulting new game session. </p> <p>You can use this operation to track the progress of matchmaking requests (through polling) as an alternative to using event notifications. See more details on tracking matchmaking requests through polling or notifications in <a>StartMatchmaking</a>. </p> <p>To request matchmaking tickets, provide a list of up to 10 ticket IDs. If the request is successful, a ticket object is returned for each requested ID that currently exists.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguidematch-notification.html"> Set Up FlexMatch Event Notification</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
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
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Security-Token")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Security-Token", valid_594572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594573 = header.getOrDefault("X-Amz-Target")
  valid_594573 = validateParameter(valid_594573, JString, required = true, default = newJString(
      "GameLift.DescribeMatchmaking"))
  if valid_594573 != nil:
    section.add "X-Amz-Target", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Content-Sha256", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Algorithm")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Algorithm", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Signature")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Signature", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-SignedHeaders", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Credential")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Credential", valid_594578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594580: Call_DescribeMatchmaking_594568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves one or more matchmaking tickets. Use this operation to retrieve ticket information, including status and--once a successful match is made--acquire connection information for the resulting new game session. </p> <p>You can use this operation to track the progress of matchmaking requests (through polling) as an alternative to using event notifications. See more details on tracking matchmaking requests through polling or notifications in <a>StartMatchmaking</a>. </p> <p>To request matchmaking tickets, provide a list of up to 10 ticket IDs. If the request is successful, a ticket object is returned for each requested ID that currently exists.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguidematch-notification.html"> Set Up FlexMatch Event Notification</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ## 
  let valid = call_594580.validator(path, query, header, formData, body)
  let scheme = call_594580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594580.url(scheme.get, call_594580.host, call_594580.base,
                         call_594580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594580, url, valid)

proc call*(call_594581: Call_DescribeMatchmaking_594568; body: JsonNode): Recallable =
  ## describeMatchmaking
  ## <p>Retrieves one or more matchmaking tickets. Use this operation to retrieve ticket information, including status and--once a successful match is made--acquire connection information for the resulting new game session. </p> <p>You can use this operation to track the progress of matchmaking requests (through polling) as an alternative to using event notifications. See more details on tracking matchmaking requests through polling or notifications in <a>StartMatchmaking</a>. </p> <p>To request matchmaking tickets, provide a list of up to 10 ticket IDs. If the request is successful, a ticket object is returned for each requested ID that currently exists.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguidematch-notification.html"> Set Up FlexMatch Event Notification</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594582 = newJObject()
  if body != nil:
    body_594582 = body
  result = call_594581.call(nil, nil, nil, nil, body_594582)

var describeMatchmaking* = Call_DescribeMatchmaking_594568(
    name: "describeMatchmaking", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeMatchmaking",
    validator: validate_DescribeMatchmaking_594569, base: "/",
    url: url_DescribeMatchmaking_594570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMatchmakingConfigurations_594583 = ref object of OpenApiRestCall_593437
proc url_DescribeMatchmakingConfigurations_594585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMatchmakingConfigurations_594584(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the details of FlexMatch matchmaking configurations. With this operation, you have the following options: (1) retrieve all existing configurations, (2) provide the names of one or more configurations to retrieve, or (3) retrieve all configurations that use a specified rule set name. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a configuration is returned for each requested name. When specifying a list of names, only configurations that currently exist are returned. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/matchmaker-build.html"> Setting Up FlexMatch Matchmakers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_594586 = header.getOrDefault("X-Amz-Date")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Date", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Security-Token")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Security-Token", valid_594587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594588 = header.getOrDefault("X-Amz-Target")
  valid_594588 = validateParameter(valid_594588, JString, required = true, default = newJString(
      "GameLift.DescribeMatchmakingConfigurations"))
  if valid_594588 != nil:
    section.add "X-Amz-Target", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Content-Sha256", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Algorithm")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Algorithm", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Signature")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Signature", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-SignedHeaders", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Credential")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Credential", valid_594593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594595: Call_DescribeMatchmakingConfigurations_594583;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves the details of FlexMatch matchmaking configurations. With this operation, you have the following options: (1) retrieve all existing configurations, (2) provide the names of one or more configurations to retrieve, or (3) retrieve all configurations that use a specified rule set name. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a configuration is returned for each requested name. When specifying a list of names, only configurations that currently exist are returned. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/matchmaker-build.html"> Setting Up FlexMatch Matchmakers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_594595.validator(path, query, header, formData, body)
  let scheme = call_594595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594595.url(scheme.get, call_594595.host, call_594595.base,
                         call_594595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594595, url, valid)

proc call*(call_594596: Call_DescribeMatchmakingConfigurations_594583;
          body: JsonNode): Recallable =
  ## describeMatchmakingConfigurations
  ## <p>Retrieves the details of FlexMatch matchmaking configurations. With this operation, you have the following options: (1) retrieve all existing configurations, (2) provide the names of one or more configurations to retrieve, or (3) retrieve all configurations that use a specified rule set name. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a configuration is returned for each requested name. When specifying a list of names, only configurations that currently exist are returned. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/matchmaker-build.html"> Setting Up FlexMatch Matchmakers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594597 = newJObject()
  if body != nil:
    body_594597 = body
  result = call_594596.call(nil, nil, nil, nil, body_594597)

var describeMatchmakingConfigurations* = Call_DescribeMatchmakingConfigurations_594583(
    name: "describeMatchmakingConfigurations", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeMatchmakingConfigurations",
    validator: validate_DescribeMatchmakingConfigurations_594584, base: "/",
    url: url_DescribeMatchmakingConfigurations_594585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMatchmakingRuleSets_594598 = ref object of OpenApiRestCall_593437
proc url_DescribeMatchmakingRuleSets_594600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMatchmakingRuleSets_594599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the details for FlexMatch matchmaking rule sets. You can request all existing rule sets for the region, or provide a list of one or more rule set names. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a rule set is returned for each requested name. </p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_594601 = header.getOrDefault("X-Amz-Date")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Date", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Security-Token")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Security-Token", valid_594602
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594603 = header.getOrDefault("X-Amz-Target")
  valid_594603 = validateParameter(valid_594603, JString, required = true, default = newJString(
      "GameLift.DescribeMatchmakingRuleSets"))
  if valid_594603 != nil:
    section.add "X-Amz-Target", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Content-Sha256", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Algorithm")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Algorithm", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-SignedHeaders", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Credential")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Credential", valid_594608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594610: Call_DescribeMatchmakingRuleSets_594598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the details for FlexMatch matchmaking rule sets. You can request all existing rule sets for the region, or provide a list of one or more rule set names. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a rule set is returned for each requested name. </p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_594610.validator(path, query, header, formData, body)
  let scheme = call_594610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594610.url(scheme.get, call_594610.host, call_594610.base,
                         call_594610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594610, url, valid)

proc call*(call_594611: Call_DescribeMatchmakingRuleSets_594598; body: JsonNode): Recallable =
  ## describeMatchmakingRuleSets
  ## <p>Retrieves the details for FlexMatch matchmaking rule sets. You can request all existing rule sets for the region, or provide a list of one or more rule set names. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a rule set is returned for each requested name. </p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594612 = newJObject()
  if body != nil:
    body_594612 = body
  result = call_594611.call(nil, nil, nil, nil, body_594612)

var describeMatchmakingRuleSets* = Call_DescribeMatchmakingRuleSets_594598(
    name: "describeMatchmakingRuleSets", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeMatchmakingRuleSets",
    validator: validate_DescribeMatchmakingRuleSets_594599, base: "/",
    url: url_DescribeMatchmakingRuleSets_594600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePlayerSessions_594613 = ref object of OpenApiRestCall_593437
proc url_DescribePlayerSessions_594615(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePlayerSessions_594614(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves properties for one or more player sessions. This action can be used in several ways: (1) provide a <code>PlayerSessionId</code> to request properties for a specific player session; (2) provide a <code>GameSessionId</code> to request properties for all player sessions in the specified game session; (3) provide a <code>PlayerId</code> to request properties for all player sessions of a specified player. </p> <p>To get game session record(s), specify only one of the following: a player session ID, a game session ID, or a player ID. You can filter this request by player session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>PlayerSession</a> object is returned for each session matching the request.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594616 = header.getOrDefault("X-Amz-Date")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Date", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Security-Token")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Security-Token", valid_594617
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594618 = header.getOrDefault("X-Amz-Target")
  valid_594618 = validateParameter(valid_594618, JString, required = true, default = newJString(
      "GameLift.DescribePlayerSessions"))
  if valid_594618 != nil:
    section.add "X-Amz-Target", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Content-Sha256", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Algorithm")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Algorithm", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Signature")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Signature", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-SignedHeaders", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Credential")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Credential", valid_594623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594625: Call_DescribePlayerSessions_594613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves properties for one or more player sessions. This action can be used in several ways: (1) provide a <code>PlayerSessionId</code> to request properties for a specific player session; (2) provide a <code>GameSessionId</code> to request properties for all player sessions in the specified game session; (3) provide a <code>PlayerId</code> to request properties for all player sessions of a specified player. </p> <p>To get game session record(s), specify only one of the following: a player session ID, a game session ID, or a player ID. You can filter this request by player session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>PlayerSession</a> object is returned for each session matching the request.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594625.validator(path, query, header, formData, body)
  let scheme = call_594625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594625.url(scheme.get, call_594625.host, call_594625.base,
                         call_594625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594625, url, valid)

proc call*(call_594626: Call_DescribePlayerSessions_594613; body: JsonNode): Recallable =
  ## describePlayerSessions
  ## <p>Retrieves properties for one or more player sessions. This action can be used in several ways: (1) provide a <code>PlayerSessionId</code> to request properties for a specific player session; (2) provide a <code>GameSessionId</code> to request properties for all player sessions in the specified game session; (3) provide a <code>PlayerId</code> to request properties for all player sessions of a specified player. </p> <p>To get game session record(s), specify only one of the following: a player session ID, a game session ID, or a player ID. You can filter this request by player session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a <a>PlayerSession</a> object is returned for each session matching the request.</p> <p> <i>Available in Amazon GameLift Local.</i> </p> <ul> <li> <p> <a>CreatePlayerSession</a> </p> </li> <li> <p> <a>CreatePlayerSessions</a> </p> </li> <li> <p> <a>DescribePlayerSessions</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594627 = newJObject()
  if body != nil:
    body_594627 = body
  result = call_594626.call(nil, nil, nil, nil, body_594627)

var describePlayerSessions* = Call_DescribePlayerSessions_594613(
    name: "describePlayerSessions", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribePlayerSessions",
    validator: validate_DescribePlayerSessions_594614, base: "/",
    url: url_DescribePlayerSessions_594615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRuntimeConfiguration_594628 = ref object of OpenApiRestCall_593437
proc url_DescribeRuntimeConfiguration_594630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRuntimeConfiguration_594629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the current run-time configuration for the specified fleet. The run-time configuration tells Amazon GameLift how to launch server processes on instances in the fleet.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594631 = header.getOrDefault("X-Amz-Date")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Date", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Security-Token")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Security-Token", valid_594632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594633 = header.getOrDefault("X-Amz-Target")
  valid_594633 = validateParameter(valid_594633, JString, required = true, default = newJString(
      "GameLift.DescribeRuntimeConfiguration"))
  if valid_594633 != nil:
    section.add "X-Amz-Target", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Content-Sha256", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Algorithm")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Algorithm", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Signature")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Signature", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-SignedHeaders", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Credential")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Credential", valid_594638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594640: Call_DescribeRuntimeConfiguration_594628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the current run-time configuration for the specified fleet. The run-time configuration tells Amazon GameLift how to launch server processes on instances in the fleet.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594640.validator(path, query, header, formData, body)
  let scheme = call_594640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594640.url(scheme.get, call_594640.host, call_594640.base,
                         call_594640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594640, url, valid)

proc call*(call_594641: Call_DescribeRuntimeConfiguration_594628; body: JsonNode): Recallable =
  ## describeRuntimeConfiguration
  ## <p>Retrieves the current run-time configuration for the specified fleet. The run-time configuration tells Amazon GameLift how to launch server processes on instances in the fleet.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594642 = newJObject()
  if body != nil:
    body_594642 = body
  result = call_594641.call(nil, nil, nil, nil, body_594642)

var describeRuntimeConfiguration* = Call_DescribeRuntimeConfiguration_594628(
    name: "describeRuntimeConfiguration", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeRuntimeConfiguration",
    validator: validate_DescribeRuntimeConfiguration_594629, base: "/",
    url: url_DescribeRuntimeConfiguration_594630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScalingPolicies_594643 = ref object of OpenApiRestCall_593437
proc url_DescribeScalingPolicies_594645(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeScalingPolicies_594644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves all scaling policies applied to a fleet.</p> <p>To get a fleet's scaling policies, specify the fleet ID. You can filter this request by policy status, such as to retrieve only active scaling policies. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, set of <a>ScalingPolicy</a> objects is returned for the fleet.</p> <p>A fleet may have all of its scaling policies suspended (<a>StopFleetActions</a>). This action does not affect the status of the scaling policies, which remains ACTIVE. To see whether a fleet's scaling policies are in force or suspended, call <a>DescribeFleetAttributes</a> and check the stopped actions.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594646 = header.getOrDefault("X-Amz-Date")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Date", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Security-Token")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Security-Token", valid_594647
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594648 = header.getOrDefault("X-Amz-Target")
  valid_594648 = validateParameter(valid_594648, JString, required = true, default = newJString(
      "GameLift.DescribeScalingPolicies"))
  if valid_594648 != nil:
    section.add "X-Amz-Target", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Content-Sha256", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Algorithm")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Algorithm", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Signature")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Signature", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-SignedHeaders", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Credential")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Credential", valid_594653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594655: Call_DescribeScalingPolicies_594643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all scaling policies applied to a fleet.</p> <p>To get a fleet's scaling policies, specify the fleet ID. You can filter this request by policy status, such as to retrieve only active scaling policies. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, set of <a>ScalingPolicy</a> objects is returned for the fleet.</p> <p>A fleet may have all of its scaling policies suspended (<a>StopFleetActions</a>). This action does not affect the status of the scaling policies, which remains ACTIVE. To see whether a fleet's scaling policies are in force or suspended, call <a>DescribeFleetAttributes</a> and check the stopped actions.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594655.validator(path, query, header, formData, body)
  let scheme = call_594655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594655.url(scheme.get, call_594655.host, call_594655.base,
                         call_594655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594655, url, valid)

proc call*(call_594656: Call_DescribeScalingPolicies_594643; body: JsonNode): Recallable =
  ## describeScalingPolicies
  ## <p>Retrieves all scaling policies applied to a fleet.</p> <p>To get a fleet's scaling policies, specify the fleet ID. You can filter this request by policy status, such as to retrieve only active scaling policies. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, set of <a>ScalingPolicy</a> objects is returned for the fleet.</p> <p>A fleet may have all of its scaling policies suspended (<a>StopFleetActions</a>). This action does not affect the status of the scaling policies, which remains ACTIVE. To see whether a fleet's scaling policies are in force or suspended, call <a>DescribeFleetAttributes</a> and check the stopped actions.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594657 = newJObject()
  if body != nil:
    body_594657 = body
  result = call_594656.call(nil, nil, nil, nil, body_594657)

var describeScalingPolicies* = Call_DescribeScalingPolicies_594643(
    name: "describeScalingPolicies", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeScalingPolicies",
    validator: validate_DescribeScalingPolicies_594644, base: "/",
    url: url_DescribeScalingPolicies_594645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeScript_594658 = ref object of OpenApiRestCall_593437
proc url_DescribeScript_594660(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeScript_594659(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves properties for a Realtime script. </p> <p>To request a script record, specify the script ID. If successful, an object containing the script properties is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
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
  var valid_594661 = header.getOrDefault("X-Amz-Date")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Date", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Security-Token")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Security-Token", valid_594662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594663 = header.getOrDefault("X-Amz-Target")
  valid_594663 = validateParameter(valid_594663, JString, required = true, default = newJString(
      "GameLift.DescribeScript"))
  if valid_594663 != nil:
    section.add "X-Amz-Target", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Content-Sha256", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Algorithm")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Algorithm", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Signature")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Signature", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-SignedHeaders", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Credential")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Credential", valid_594668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594670: Call_DescribeScript_594658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves properties for a Realtime script. </p> <p>To request a script record, specify the script ID. If successful, an object containing the script properties is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ## 
  let valid = call_594670.validator(path, query, header, formData, body)
  let scheme = call_594670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594670.url(scheme.get, call_594670.host, call_594670.base,
                         call_594670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594670, url, valid)

proc call*(call_594671: Call_DescribeScript_594658; body: JsonNode): Recallable =
  ## describeScript
  ## <p>Retrieves properties for a Realtime script. </p> <p>To request a script record, specify the script ID. If successful, an object containing the script properties is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594672 = newJObject()
  if body != nil:
    body_594672 = body
  result = call_594671.call(nil, nil, nil, nil, body_594672)

var describeScript* = Call_DescribeScript_594658(name: "describeScript",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeScript",
    validator: validate_DescribeScript_594659, base: "/", url: url_DescribeScript_594660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVpcPeeringAuthorizations_594673 = ref object of OpenApiRestCall_593437
proc url_DescribeVpcPeeringAuthorizations_594675(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeVpcPeeringAuthorizations_594674(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves valid VPC peering authorizations that are pending for the AWS account. This operation returns all VPC peering authorizations and requests for peering. This includes those initiated and received by this account. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
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
  var valid_594676 = header.getOrDefault("X-Amz-Date")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Date", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Security-Token")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Security-Token", valid_594677
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594678 = header.getOrDefault("X-Amz-Target")
  valid_594678 = validateParameter(valid_594678, JString, required = true, default = newJString(
      "GameLift.DescribeVpcPeeringAuthorizations"))
  if valid_594678 != nil:
    section.add "X-Amz-Target", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Content-Sha256", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Algorithm")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Algorithm", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Signature")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Signature", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-SignedHeaders", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Credential")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Credential", valid_594683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594685: Call_DescribeVpcPeeringAuthorizations_594673;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieves valid VPC peering authorizations that are pending for the AWS account. This operation returns all VPC peering authorizations and requests for peering. This includes those initiated and received by this account. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ## 
  let valid = call_594685.validator(path, query, header, formData, body)
  let scheme = call_594685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594685.url(scheme.get, call_594685.host, call_594685.base,
                         call_594685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594685, url, valid)

proc call*(call_594686: Call_DescribeVpcPeeringAuthorizations_594673;
          body: JsonNode): Recallable =
  ## describeVpcPeeringAuthorizations
  ## <p>Retrieves valid VPC peering authorizations that are pending for the AWS account. This operation returns all VPC peering authorizations and requests for peering. This includes those initiated and received by this account. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594687 = newJObject()
  if body != nil:
    body_594687 = body
  result = call_594686.call(nil, nil, nil, nil, body_594687)

var describeVpcPeeringAuthorizations* = Call_DescribeVpcPeeringAuthorizations_594673(
    name: "describeVpcPeeringAuthorizations", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeVpcPeeringAuthorizations",
    validator: validate_DescribeVpcPeeringAuthorizations_594674, base: "/",
    url: url_DescribeVpcPeeringAuthorizations_594675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVpcPeeringConnections_594688 = ref object of OpenApiRestCall_593437
proc url_DescribeVpcPeeringConnections_594690(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeVpcPeeringConnections_594689(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves information on VPC peering connections. Use this operation to get peering information for all fleets or for one specific fleet ID. </p> <p>To retrieve connection information, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Specify a fleet ID or leave the parameter empty to retrieve all connection records. If successful, the retrieved information includes both active and pending connections. Active connections identify the IpV4 CIDR block that the VPC uses to connect. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
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
  var valid_594691 = header.getOrDefault("X-Amz-Date")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Date", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Security-Token")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Security-Token", valid_594692
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594693 = header.getOrDefault("X-Amz-Target")
  valid_594693 = validateParameter(valid_594693, JString, required = true, default = newJString(
      "GameLift.DescribeVpcPeeringConnections"))
  if valid_594693 != nil:
    section.add "X-Amz-Target", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Content-Sha256", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Algorithm")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Algorithm", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Signature")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Signature", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-SignedHeaders", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Credential")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Credential", valid_594698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594700: Call_DescribeVpcPeeringConnections_594688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information on VPC peering connections. Use this operation to get peering information for all fleets or for one specific fleet ID. </p> <p>To retrieve connection information, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Specify a fleet ID or leave the parameter empty to retrieve all connection records. If successful, the retrieved information includes both active and pending connections. Active connections identify the IpV4 CIDR block that the VPC uses to connect. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ## 
  let valid = call_594700.validator(path, query, header, formData, body)
  let scheme = call_594700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594700.url(scheme.get, call_594700.host, call_594700.base,
                         call_594700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594700, url, valid)

proc call*(call_594701: Call_DescribeVpcPeeringConnections_594688; body: JsonNode): Recallable =
  ## describeVpcPeeringConnections
  ## <p>Retrieves information on VPC peering connections. Use this operation to get peering information for all fleets or for one specific fleet ID. </p> <p>To retrieve connection information, call this operation from the AWS account that is used to manage the Amazon GameLift fleets. Specify a fleet ID or leave the parameter empty to retrieve all connection records. If successful, the retrieved information includes both active and pending connections. Active connections identify the IpV4 CIDR block that the VPC uses to connect. </p> <ul> <li> <p> <a>CreateVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>DescribeVpcPeeringAuthorizations</a> </p> </li> <li> <p> <a>DeleteVpcPeeringAuthorization</a> </p> </li> <li> <p> <a>CreateVpcPeeringConnection</a> </p> </li> <li> <p> <a>DescribeVpcPeeringConnections</a> </p> </li> <li> <p> <a>DeleteVpcPeeringConnection</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594702 = newJObject()
  if body != nil:
    body_594702 = body
  result = call_594701.call(nil, nil, nil, nil, body_594702)

var describeVpcPeeringConnections* = Call_DescribeVpcPeeringConnections_594688(
    name: "describeVpcPeeringConnections", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.DescribeVpcPeeringConnections",
    validator: validate_DescribeVpcPeeringConnections_594689, base: "/",
    url: url_DescribeVpcPeeringConnections_594690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGameSessionLogUrl_594703 = ref object of OpenApiRestCall_593437
proc url_GetGameSessionLogUrl_594705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGameSessionLogUrl_594704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the location of stored game session logs for a specified game session. When a game session is terminated, Amazon GameLift automatically stores the logs in Amazon S3 and retains them for 14 days. Use this URL to download the logs.</p> <note> <p>See the <a href="https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_gamelift">AWS Service Limits</a> page for maximum log file sizes. Log files that exceed this limit are not saved.</p> </note> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594706 = header.getOrDefault("X-Amz-Date")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Date", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Security-Token")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Security-Token", valid_594707
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594708 = header.getOrDefault("X-Amz-Target")
  valid_594708 = validateParameter(valid_594708, JString, required = true, default = newJString(
      "GameLift.GetGameSessionLogUrl"))
  if valid_594708 != nil:
    section.add "X-Amz-Target", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Content-Sha256", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Algorithm")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Algorithm", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Signature")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Signature", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-SignedHeaders", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Credential")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Credential", valid_594713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594715: Call_GetGameSessionLogUrl_594703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the location of stored game session logs for a specified game session. When a game session is terminated, Amazon GameLift automatically stores the logs in Amazon S3 and retains them for 14 days. Use this URL to download the logs.</p> <note> <p>See the <a href="https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_gamelift">AWS Service Limits</a> page for maximum log file sizes. Log files that exceed this limit are not saved.</p> </note> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594715.validator(path, query, header, formData, body)
  let scheme = call_594715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594715.url(scheme.get, call_594715.host, call_594715.base,
                         call_594715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594715, url, valid)

proc call*(call_594716: Call_GetGameSessionLogUrl_594703; body: JsonNode): Recallable =
  ## getGameSessionLogUrl
  ## <p>Retrieves the location of stored game session logs for a specified game session. When a game session is terminated, Amazon GameLift automatically stores the logs in Amazon S3 and retains them for 14 days. Use this URL to download the logs.</p> <note> <p>See the <a href="https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_gamelift">AWS Service Limits</a> page for maximum log file sizes. Log files that exceed this limit are not saved.</p> </note> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594717 = newJObject()
  if body != nil:
    body_594717 = body
  result = call_594716.call(nil, nil, nil, nil, body_594717)

var getGameSessionLogUrl* = Call_GetGameSessionLogUrl_594703(
    name: "getGameSessionLogUrl", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.GetGameSessionLogUrl",
    validator: validate_GetGameSessionLogUrl_594704, base: "/",
    url: url_GetGameSessionLogUrl_594705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInstanceAccess_594718 = ref object of OpenApiRestCall_593437
proc url_GetInstanceAccess_594720(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetInstanceAccess_594719(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Requests remote access to a fleet instance. Remote access is useful for debugging, gathering benchmarking data, or watching activity in real time. </p> <p>Access requires credentials that match the operating system of the instance. For a Windows instance, Amazon GameLift returns a user name and password as strings for use with a Windows Remote Desktop client. For a Linux instance, Amazon GameLift returns a user name and RSA private key, also as strings, for use with an SSH client. The private key must be saved in the proper format to a <code>.pem</code> file before using. If you're making this request using the AWS CLI, saving the secret can be handled as part of the GetInstanceAccess request. (See the example later in this topic). For more information on remote access, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-remote-access.html">Remotely Accessing an Instance</a>.</p> <p>To request access to a specific instance, specify the IDs of both the instance and the fleet it belongs to. You can retrieve a fleet's instance IDs by calling <a>DescribeInstances</a>. If successful, an <a>InstanceAccess</a> object is returned containing the instance's IP address and a set of credentials.</p>
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
  var valid_594721 = header.getOrDefault("X-Amz-Date")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Date", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Security-Token")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Security-Token", valid_594722
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594723 = header.getOrDefault("X-Amz-Target")
  valid_594723 = validateParameter(valid_594723, JString, required = true, default = newJString(
      "GameLift.GetInstanceAccess"))
  if valid_594723 != nil:
    section.add "X-Amz-Target", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Content-Sha256", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Algorithm")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Algorithm", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Signature")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Signature", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-SignedHeaders", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Credential")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Credential", valid_594728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594730: Call_GetInstanceAccess_594718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Requests remote access to a fleet instance. Remote access is useful for debugging, gathering benchmarking data, or watching activity in real time. </p> <p>Access requires credentials that match the operating system of the instance. For a Windows instance, Amazon GameLift returns a user name and password as strings for use with a Windows Remote Desktop client. For a Linux instance, Amazon GameLift returns a user name and RSA private key, also as strings, for use with an SSH client. The private key must be saved in the proper format to a <code>.pem</code> file before using. If you're making this request using the AWS CLI, saving the secret can be handled as part of the GetInstanceAccess request. (See the example later in this topic). For more information on remote access, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-remote-access.html">Remotely Accessing an Instance</a>.</p> <p>To request access to a specific instance, specify the IDs of both the instance and the fleet it belongs to. You can retrieve a fleet's instance IDs by calling <a>DescribeInstances</a>. If successful, an <a>InstanceAccess</a> object is returned containing the instance's IP address and a set of credentials.</p>
  ## 
  let valid = call_594730.validator(path, query, header, formData, body)
  let scheme = call_594730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594730.url(scheme.get, call_594730.host, call_594730.base,
                         call_594730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594730, url, valid)

proc call*(call_594731: Call_GetInstanceAccess_594718; body: JsonNode): Recallable =
  ## getInstanceAccess
  ## <p>Requests remote access to a fleet instance. Remote access is useful for debugging, gathering benchmarking data, or watching activity in real time. </p> <p>Access requires credentials that match the operating system of the instance. For a Windows instance, Amazon GameLift returns a user name and password as strings for use with a Windows Remote Desktop client. For a Linux instance, Amazon GameLift returns a user name and RSA private key, also as strings, for use with an SSH client. The private key must be saved in the proper format to a <code>.pem</code> file before using. If you're making this request using the AWS CLI, saving the secret can be handled as part of the GetInstanceAccess request. (See the example later in this topic). For more information on remote access, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-remote-access.html">Remotely Accessing an Instance</a>.</p> <p>To request access to a specific instance, specify the IDs of both the instance and the fleet it belongs to. You can retrieve a fleet's instance IDs by calling <a>DescribeInstances</a>. If successful, an <a>InstanceAccess</a> object is returned containing the instance's IP address and a set of credentials.</p>
  ##   body: JObject (required)
  var body_594732 = newJObject()
  if body != nil:
    body_594732 = body
  result = call_594731.call(nil, nil, nil, nil, body_594732)

var getInstanceAccess* = Call_GetInstanceAccess_594718(name: "getInstanceAccess",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.GetInstanceAccess",
    validator: validate_GetInstanceAccess_594719, base: "/",
    url: url_GetInstanceAccess_594720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_594733 = ref object of OpenApiRestCall_593437
proc url_ListAliases_594735(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAliases_594734(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves all aliases for this AWS account. You can filter the result set by alias name and/or routing strategy type. Use the pagination parameters to retrieve results in sequential pages.</p> <note> <p>Returned aliases are not listed in any particular order.</p> </note> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
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
  var valid_594736 = header.getOrDefault("X-Amz-Date")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Date", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Security-Token")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Security-Token", valid_594737
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594738 = header.getOrDefault("X-Amz-Target")
  valid_594738 = validateParameter(valid_594738, JString, required = true,
                                 default = newJString("GameLift.ListAliases"))
  if valid_594738 != nil:
    section.add "X-Amz-Target", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Content-Sha256", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Algorithm")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Algorithm", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Signature")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Signature", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-SignedHeaders", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Credential")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Credential", valid_594743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594745: Call_ListAliases_594733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all aliases for this AWS account. You can filter the result set by alias name and/or routing strategy type. Use the pagination parameters to retrieve results in sequential pages.</p> <note> <p>Returned aliases are not listed in any particular order.</p> </note> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ## 
  let valid = call_594745.validator(path, query, header, formData, body)
  let scheme = call_594745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594745.url(scheme.get, call_594745.host, call_594745.base,
                         call_594745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594745, url, valid)

proc call*(call_594746: Call_ListAliases_594733; body: JsonNode): Recallable =
  ## listAliases
  ## <p>Retrieves all aliases for this AWS account. You can filter the result set by alias name and/or routing strategy type. Use the pagination parameters to retrieve results in sequential pages.</p> <note> <p>Returned aliases are not listed in any particular order.</p> </note> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594747 = newJObject()
  if body != nil:
    body_594747 = body
  result = call_594746.call(nil, nil, nil, nil, body_594747)

var listAliases* = Call_ListAliases_594733(name: "listAliases",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.ListAliases",
                                        validator: validate_ListAliases_594734,
                                        base: "/", url: url_ListAliases_594735,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBuilds_594748 = ref object of OpenApiRestCall_593437
proc url_ListBuilds_594750(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBuilds_594749(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves build records for all builds associated with the AWS account in use. You can limit results to builds that are in a specific status by using the <code>Status</code> parameter. Use the pagination parameters to retrieve results in a set of sequential pages. </p> <note> <p>Build records are not listed in any particular order.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
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
  var valid_594751 = header.getOrDefault("X-Amz-Date")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Date", valid_594751
  var valid_594752 = header.getOrDefault("X-Amz-Security-Token")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Security-Token", valid_594752
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594753 = header.getOrDefault("X-Amz-Target")
  valid_594753 = validateParameter(valid_594753, JString, required = true,
                                 default = newJString("GameLift.ListBuilds"))
  if valid_594753 != nil:
    section.add "X-Amz-Target", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Content-Sha256", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Algorithm")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Algorithm", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Signature")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Signature", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-SignedHeaders", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Credential")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Credential", valid_594758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594760: Call_ListBuilds_594748; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves build records for all builds associated with the AWS account in use. You can limit results to builds that are in a specific status by using the <code>Status</code> parameter. Use the pagination parameters to retrieve results in a set of sequential pages. </p> <note> <p>Build records are not listed in any particular order.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ## 
  let valid = call_594760.validator(path, query, header, formData, body)
  let scheme = call_594760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594760.url(scheme.get, call_594760.host, call_594760.base,
                         call_594760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594760, url, valid)

proc call*(call_594761: Call_ListBuilds_594748; body: JsonNode): Recallable =
  ## listBuilds
  ## <p>Retrieves build records for all builds associated with the AWS account in use. You can limit results to builds that are in a specific status by using the <code>Status</code> parameter. Use the pagination parameters to retrieve results in a set of sequential pages. </p> <note> <p>Build records are not listed in any particular order.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594762 = newJObject()
  if body != nil:
    body_594762 = body
  result = call_594761.call(nil, nil, nil, nil, body_594762)

var listBuilds* = Call_ListBuilds_594748(name: "listBuilds",
                                      meth: HttpMethod.HttpPost,
                                      host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.ListBuilds",
                                      validator: validate_ListBuilds_594749,
                                      base: "/", url: url_ListBuilds_594750,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_594763 = ref object of OpenApiRestCall_593437
proc url_ListFleets_594765(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFleets_594764(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a collection of fleet records for this AWS account. You can filter the result set to find only those fleets that are deployed with a specific build or script. Use the pagination parameters to retrieve results in sequential pages.</p> <note> <p>Fleet records are not listed in a particular order.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Set Up Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594766 = header.getOrDefault("X-Amz-Date")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Date", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Security-Token")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Security-Token", valid_594767
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594768 = header.getOrDefault("X-Amz-Target")
  valid_594768 = validateParameter(valid_594768, JString, required = true,
                                 default = newJString("GameLift.ListFleets"))
  if valid_594768 != nil:
    section.add "X-Amz-Target", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Content-Sha256", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-Algorithm")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Algorithm", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Signature")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Signature", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-SignedHeaders", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Credential")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Credential", valid_594773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594775: Call_ListFleets_594763; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a collection of fleet records for this AWS account. You can filter the result set to find only those fleets that are deployed with a specific build or script. Use the pagination parameters to retrieve results in sequential pages.</p> <note> <p>Fleet records are not listed in a particular order.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Set Up Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594775.validator(path, query, header, formData, body)
  let scheme = call_594775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594775.url(scheme.get, call_594775.host, call_594775.base,
                         call_594775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594775, url, valid)

proc call*(call_594776: Call_ListFleets_594763; body: JsonNode): Recallable =
  ## listFleets
  ## <p>Retrieves a collection of fleet records for this AWS account. You can filter the result set to find only those fleets that are deployed with a specific build or script. Use the pagination parameters to retrieve results in sequential pages.</p> <note> <p>Fleet records are not listed in a particular order.</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Set Up Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594777 = newJObject()
  if body != nil:
    body_594777 = body
  result = call_594776.call(nil, nil, nil, nil, body_594777)

var listFleets* = Call_ListFleets_594763(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.ListFleets",
                                      validator: validate_ListFleets_594764,
                                      base: "/", url: url_ListFleets_594765,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListScripts_594778 = ref object of OpenApiRestCall_593437
proc url_ListScripts_594780(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListScripts_594779(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves script records for all Realtime scripts that are associated with the AWS account in use. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
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
  var valid_594781 = header.getOrDefault("X-Amz-Date")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Date", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Security-Token")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Security-Token", valid_594782
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594783 = header.getOrDefault("X-Amz-Target")
  valid_594783 = validateParameter(valid_594783, JString, required = true,
                                 default = newJString("GameLift.ListScripts"))
  if valid_594783 != nil:
    section.add "X-Amz-Target", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Content-Sha256", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-Algorithm")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-Algorithm", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-Signature")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-Signature", valid_594786
  var valid_594787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "X-Amz-SignedHeaders", valid_594787
  var valid_594788 = header.getOrDefault("X-Amz-Credential")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "X-Amz-Credential", valid_594788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594790: Call_ListScripts_594778; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves script records for all Realtime scripts that are associated with the AWS account in use. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ## 
  let valid = call_594790.validator(path, query, header, formData, body)
  let scheme = call_594790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594790.url(scheme.get, call_594790.host, call_594790.base,
                         call_594790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594790, url, valid)

proc call*(call_594791: Call_ListScripts_594778; body: JsonNode): Recallable =
  ## listScripts
  ## <p>Retrieves script records for all Realtime scripts that are associated with the AWS account in use. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594792 = newJObject()
  if body != nil:
    body_594792 = body
  result = call_594791.call(nil, nil, nil, nil, body_594792)

var listScripts* = Call_ListScripts_594778(name: "listScripts",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.ListScripts",
                                        validator: validate_ListScripts_594779,
                                        base: "/", url: url_ListScripts_594780,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutScalingPolicy_594793 = ref object of OpenApiRestCall_593437
proc url_PutScalingPolicy_594795(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutScalingPolicy_594794(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates or updates a scaling policy for a fleet. Scaling policies are used to automatically scale a fleet's hosting capacity to meet player demand. An active scaling policy instructs Amazon GameLift to track a fleet metric and automatically change the fleet's capacity when a certain threshold is reached. There are two types of scaling policies: target-based and rule-based. Use a target-based policy to quickly and efficiently manage fleet scaling; this option is the most commonly used. Use rule-based policies when you need to exert fine-grained control over auto-scaling. </p> <p>Fleets can have multiple scaling policies of each type in force at the same time; you can have one target-based policy, one or multiple rule-based scaling policies, or both. We recommend caution, however, because multiple auto-scaling policies can have unintended consequences.</p> <p>You can temporarily suspend all scaling policies for a fleet by calling <a>StopFleetActions</a> with the fleet action AUTO_SCALING. To resume scaling policies, call <a>StartFleetActions</a> with the same fleet action. To stop just one scaling policy--or to permanently remove it, you must delete the policy with <a>DeleteScalingPolicy</a>.</p> <p>Learn more about how to work with auto-scaling in <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-autoscaling.html">Set Up Fleet Automatic Scaling</a>.</p> <p> <b>Target-based policy</b> </p> <p>A target-based policy tracks a single metric: PercentAvailableGameSessions. This metric tells us how much of a fleet's hosting capacity is ready to host game sessions but is not currently in use. This is the fleet's buffer; it measures the additional player demand that the fleet could handle at current capacity. With a target-based policy, you set your ideal buffer size and leave it to Amazon GameLift to take whatever action is needed to maintain that target. </p> <p>For example, you might choose to maintain a 10% buffer for a fleet that has the capacity to host 100 simultaneous game sessions. This policy tells Amazon GameLift to take action whenever the fleet's available capacity falls below or rises above 10 game sessions. Amazon GameLift will start new instances or stop unused instances in order to return to the 10% buffer. </p> <p>To create or update a target-based policy, specify a fleet ID and name, and set the policy type to "TargetBased". Specify the metric to track (PercentAvailableGameSessions) and reference a <a>TargetConfiguration</a> object with your desired buffer value. Exclude all other parameters. On a successful request, the policy name is returned. The scaling policy is automatically in force as soon as it's successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted.</p> <p> <b>Rule-based policy</b> </p> <p>A rule-based policy tracks specified fleet metric, sets a threshold value, and specifies the type of action to initiate when triggered. With a rule-based policy, you can select from several available fleet metrics. Each policy specifies whether to scale up or scale down (and by how much), so you need one policy for each type of action. </p> <p>For example, a policy may make the following statement: "If the percentage of idle instances is greater than 20% for more than 15 minutes, then reduce the fleet capacity by 10%."</p> <p>A policy's rule statement has the following structure:</p> <p>If <code>[MetricName]</code> is <code>[ComparisonOperator]</code> <code>[Threshold]</code> for <code>[EvaluationPeriods]</code> minutes, then <code>[ScalingAdjustmentType]</code> to/by <code>[ScalingAdjustment]</code>.</p> <p>To implement the example, the rule statement would look like this:</p> <p>If <code>[PercentIdleInstances]</code> is <code>[GreaterThanThreshold]</code> <code>[20]</code> for <code>[15]</code> minutes, then <code>[PercentChangeInCapacity]</code> to/by <code>[10]</code>.</p> <p>To create or update a scaling policy, specify a unique combination of name and fleet ID, and set the policy type to "RuleBased". Specify the parameter values for a policy rule statement. On a successful request, the policy name is returned. Scaling policies are automatically in force as soon as they're successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594796 = header.getOrDefault("X-Amz-Date")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Date", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Security-Token")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Security-Token", valid_594797
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594798 = header.getOrDefault("X-Amz-Target")
  valid_594798 = validateParameter(valid_594798, JString, required = true, default = newJString(
      "GameLift.PutScalingPolicy"))
  if valid_594798 != nil:
    section.add "X-Amz-Target", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Content-Sha256", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Algorithm")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Algorithm", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-Signature")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Signature", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-SignedHeaders", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-Credential")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Credential", valid_594803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594805: Call_PutScalingPolicy_594793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a scaling policy for a fleet. Scaling policies are used to automatically scale a fleet's hosting capacity to meet player demand. An active scaling policy instructs Amazon GameLift to track a fleet metric and automatically change the fleet's capacity when a certain threshold is reached. There are two types of scaling policies: target-based and rule-based. Use a target-based policy to quickly and efficiently manage fleet scaling; this option is the most commonly used. Use rule-based policies when you need to exert fine-grained control over auto-scaling. </p> <p>Fleets can have multiple scaling policies of each type in force at the same time; you can have one target-based policy, one or multiple rule-based scaling policies, or both. We recommend caution, however, because multiple auto-scaling policies can have unintended consequences.</p> <p>You can temporarily suspend all scaling policies for a fleet by calling <a>StopFleetActions</a> with the fleet action AUTO_SCALING. To resume scaling policies, call <a>StartFleetActions</a> with the same fleet action. To stop just one scaling policy--or to permanently remove it, you must delete the policy with <a>DeleteScalingPolicy</a>.</p> <p>Learn more about how to work with auto-scaling in <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-autoscaling.html">Set Up Fleet Automatic Scaling</a>.</p> <p> <b>Target-based policy</b> </p> <p>A target-based policy tracks a single metric: PercentAvailableGameSessions. This metric tells us how much of a fleet's hosting capacity is ready to host game sessions but is not currently in use. This is the fleet's buffer; it measures the additional player demand that the fleet could handle at current capacity. With a target-based policy, you set your ideal buffer size and leave it to Amazon GameLift to take whatever action is needed to maintain that target. </p> <p>For example, you might choose to maintain a 10% buffer for a fleet that has the capacity to host 100 simultaneous game sessions. This policy tells Amazon GameLift to take action whenever the fleet's available capacity falls below or rises above 10 game sessions. Amazon GameLift will start new instances or stop unused instances in order to return to the 10% buffer. </p> <p>To create or update a target-based policy, specify a fleet ID and name, and set the policy type to "TargetBased". Specify the metric to track (PercentAvailableGameSessions) and reference a <a>TargetConfiguration</a> object with your desired buffer value. Exclude all other parameters. On a successful request, the policy name is returned. The scaling policy is automatically in force as soon as it's successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted.</p> <p> <b>Rule-based policy</b> </p> <p>A rule-based policy tracks specified fleet metric, sets a threshold value, and specifies the type of action to initiate when triggered. With a rule-based policy, you can select from several available fleet metrics. Each policy specifies whether to scale up or scale down (and by how much), so you need one policy for each type of action. </p> <p>For example, a policy may make the following statement: "If the percentage of idle instances is greater than 20% for more than 15 minutes, then reduce the fleet capacity by 10%."</p> <p>A policy's rule statement has the following structure:</p> <p>If <code>[MetricName]</code> is <code>[ComparisonOperator]</code> <code>[Threshold]</code> for <code>[EvaluationPeriods]</code> minutes, then <code>[ScalingAdjustmentType]</code> to/by <code>[ScalingAdjustment]</code>.</p> <p>To implement the example, the rule statement would look like this:</p> <p>If <code>[PercentIdleInstances]</code> is <code>[GreaterThanThreshold]</code> <code>[20]</code> for <code>[15]</code> minutes, then <code>[PercentChangeInCapacity]</code> to/by <code>[10]</code>.</p> <p>To create or update a scaling policy, specify a unique combination of name and fleet ID, and set the policy type to "RuleBased". Specify the parameter values for a policy rule statement. On a successful request, the policy name is returned. Scaling policies are automatically in force as soon as they're successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594805.validator(path, query, header, formData, body)
  let scheme = call_594805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594805.url(scheme.get, call_594805.host, call_594805.base,
                         call_594805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594805, url, valid)

proc call*(call_594806: Call_PutScalingPolicy_594793; body: JsonNode): Recallable =
  ## putScalingPolicy
  ## <p>Creates or updates a scaling policy for a fleet. Scaling policies are used to automatically scale a fleet's hosting capacity to meet player demand. An active scaling policy instructs Amazon GameLift to track a fleet metric and automatically change the fleet's capacity when a certain threshold is reached. There are two types of scaling policies: target-based and rule-based. Use a target-based policy to quickly and efficiently manage fleet scaling; this option is the most commonly used. Use rule-based policies when you need to exert fine-grained control over auto-scaling. </p> <p>Fleets can have multiple scaling policies of each type in force at the same time; you can have one target-based policy, one or multiple rule-based scaling policies, or both. We recommend caution, however, because multiple auto-scaling policies can have unintended consequences.</p> <p>You can temporarily suspend all scaling policies for a fleet by calling <a>StopFleetActions</a> with the fleet action AUTO_SCALING. To resume scaling policies, call <a>StartFleetActions</a> with the same fleet action. To stop just one scaling policy--or to permanently remove it, you must delete the policy with <a>DeleteScalingPolicy</a>.</p> <p>Learn more about how to work with auto-scaling in <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-autoscaling.html">Set Up Fleet Automatic Scaling</a>.</p> <p> <b>Target-based policy</b> </p> <p>A target-based policy tracks a single metric: PercentAvailableGameSessions. This metric tells us how much of a fleet's hosting capacity is ready to host game sessions but is not currently in use. This is the fleet's buffer; it measures the additional player demand that the fleet could handle at current capacity. With a target-based policy, you set your ideal buffer size and leave it to Amazon GameLift to take whatever action is needed to maintain that target. </p> <p>For example, you might choose to maintain a 10% buffer for a fleet that has the capacity to host 100 simultaneous game sessions. This policy tells Amazon GameLift to take action whenever the fleet's available capacity falls below or rises above 10 game sessions. Amazon GameLift will start new instances or stop unused instances in order to return to the 10% buffer. </p> <p>To create or update a target-based policy, specify a fleet ID and name, and set the policy type to "TargetBased". Specify the metric to track (PercentAvailableGameSessions) and reference a <a>TargetConfiguration</a> object with your desired buffer value. Exclude all other parameters. On a successful request, the policy name is returned. The scaling policy is automatically in force as soon as it's successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted.</p> <p> <b>Rule-based policy</b> </p> <p>A rule-based policy tracks specified fleet metric, sets a threshold value, and specifies the type of action to initiate when triggered. With a rule-based policy, you can select from several available fleet metrics. Each policy specifies whether to scale up or scale down (and by how much), so you need one policy for each type of action. </p> <p>For example, a policy may make the following statement: "If the percentage of idle instances is greater than 20% for more than 15 minutes, then reduce the fleet capacity by 10%."</p> <p>A policy's rule statement has the following structure:</p> <p>If <code>[MetricName]</code> is <code>[ComparisonOperator]</code> <code>[Threshold]</code> for <code>[EvaluationPeriods]</code> minutes, then <code>[ScalingAdjustmentType]</code> to/by <code>[ScalingAdjustment]</code>.</p> <p>To implement the example, the rule statement would look like this:</p> <p>If <code>[PercentIdleInstances]</code> is <code>[GreaterThanThreshold]</code> <code>[20]</code> for <code>[15]</code> minutes, then <code>[PercentChangeInCapacity]</code> to/by <code>[10]</code>.</p> <p>To create or update a scaling policy, specify a unique combination of name and fleet ID, and set the policy type to "RuleBased". Specify the parameter values for a policy rule statement. On a successful request, the policy name is returned. Scaling policies are automatically in force as soon as they're successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted.</p> <ul> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p>Manage scaling policies:</p> <ul> <li> <p> <a>PutScalingPolicy</a> (auto-scaling)</p> </li> <li> <p> <a>DescribeScalingPolicies</a> (auto-scaling)</p> </li> <li> <p> <a>DeleteScalingPolicy</a> (auto-scaling)</p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594807 = newJObject()
  if body != nil:
    body_594807 = body
  result = call_594806.call(nil, nil, nil, nil, body_594807)

var putScalingPolicy* = Call_PutScalingPolicy_594793(name: "putScalingPolicy",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.PutScalingPolicy",
    validator: validate_PutScalingPolicy_594794, base: "/",
    url: url_PutScalingPolicy_594795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RequestUploadCredentials_594808 = ref object of OpenApiRestCall_593437
proc url_RequestUploadCredentials_594810(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RequestUploadCredentials_594809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a fresh set of credentials for use when uploading a new set of game build files to Amazon GameLift's Amazon S3. This is done as part of the build creation process; see <a>CreateBuild</a>.</p> <p>To request new credentials, specify the build ID as returned with an initial <code>CreateBuild</code> request. If successful, a new set of credentials are returned, along with the S3 storage location associated with the build ID.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html">Uploading Your Game</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
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
  var valid_594811 = header.getOrDefault("X-Amz-Date")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-Date", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Security-Token")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Security-Token", valid_594812
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594813 = header.getOrDefault("X-Amz-Target")
  valid_594813 = validateParameter(valid_594813, JString, required = true, default = newJString(
      "GameLift.RequestUploadCredentials"))
  if valid_594813 != nil:
    section.add "X-Amz-Target", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Content-Sha256", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Algorithm")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Algorithm", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Signature")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Signature", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-SignedHeaders", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Credential")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Credential", valid_594818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594820: Call_RequestUploadCredentials_594808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a fresh set of credentials for use when uploading a new set of game build files to Amazon GameLift's Amazon S3. This is done as part of the build creation process; see <a>CreateBuild</a>.</p> <p>To request new credentials, specify the build ID as returned with an initial <code>CreateBuild</code> request. If successful, a new set of credentials are returned, along with the S3 storage location associated with the build ID.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html">Uploading Your Game</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ## 
  let valid = call_594820.validator(path, query, header, formData, body)
  let scheme = call_594820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594820.url(scheme.get, call_594820.host, call_594820.base,
                         call_594820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594820, url, valid)

proc call*(call_594821: Call_RequestUploadCredentials_594808; body: JsonNode): Recallable =
  ## requestUploadCredentials
  ## <p>Retrieves a fresh set of credentials for use when uploading a new set of game build files to Amazon GameLift's Amazon S3. This is done as part of the build creation process; see <a>CreateBuild</a>.</p> <p>To request new credentials, specify the build ID as returned with an initial <code>CreateBuild</code> request. If successful, a new set of credentials are returned, along with the S3 storage location associated with the build ID.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html">Uploading Your Game</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594822 = newJObject()
  if body != nil:
    body_594822 = body
  result = call_594821.call(nil, nil, nil, nil, body_594822)

var requestUploadCredentials* = Call_RequestUploadCredentials_594808(
    name: "requestUploadCredentials", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.RequestUploadCredentials",
    validator: validate_RequestUploadCredentials_594809, base: "/",
    url: url_RequestUploadCredentials_594810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveAlias_594823 = ref object of OpenApiRestCall_593437
proc url_ResolveAlias_594825(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ResolveAlias_594824(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the fleet ID that a specified alias is currently pointing to.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
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
  var valid_594826 = header.getOrDefault("X-Amz-Date")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Date", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Security-Token")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Security-Token", valid_594827
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594828 = header.getOrDefault("X-Amz-Target")
  valid_594828 = validateParameter(valid_594828, JString, required = true,
                                 default = newJString("GameLift.ResolveAlias"))
  if valid_594828 != nil:
    section.add "X-Amz-Target", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Content-Sha256", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Algorithm")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Algorithm", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Signature")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Signature", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-SignedHeaders", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Credential")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Credential", valid_594833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594835: Call_ResolveAlias_594823; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the fleet ID that a specified alias is currently pointing to.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ## 
  let valid = call_594835.validator(path, query, header, formData, body)
  let scheme = call_594835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594835.url(scheme.get, call_594835.host, call_594835.base,
                         call_594835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594835, url, valid)

proc call*(call_594836: Call_ResolveAlias_594823; body: JsonNode): Recallable =
  ## resolveAlias
  ## <p>Retrieves the fleet ID that a specified alias is currently pointing to.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594837 = newJObject()
  if body != nil:
    body_594837 = body
  result = call_594836.call(nil, nil, nil, nil, body_594837)

var resolveAlias* = Call_ResolveAlias_594823(name: "resolveAlias",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.ResolveAlias",
    validator: validate_ResolveAlias_594824, base: "/", url: url_ResolveAlias_594825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchGameSessions_594838 = ref object of OpenApiRestCall_593437
proc url_SearchGameSessions_594840(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SearchGameSessions_594839(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Retrieves all active game sessions that match a set of search criteria and sorts them in a specified order. You can search or sort by the following game session attributes:</p> <ul> <li> <p> <b>gameSessionId</b> -- Unique identifier for the game session. You can use either a <code>GameSessionId</code> or <code>GameSessionArn</code> value. </p> </li> <li> <p> <b>gameSessionName</b> -- Name assigned to a game session. This value is set when requesting a new game session with <a>CreateGameSession</a> or updating with <a>UpdateGameSession</a>. Game session names do not need to be unique to a game session.</p> </li> <li> <p> <b>gameSessionProperties</b> -- Custom data defined in a game session's <code>GameProperty</code> parameter. <code>GameProperty</code> values are stored as key:value pairs; the filter expression must indicate the key and a string to search the data values for. For example, to search for game sessions with custom data containing the key:value pair "gameMode:brawl", specify the following: <code>gameSessionProperties.gameMode = "brawl"</code>. All custom data values are searched as strings.</p> </li> <li> <p> <b>maximumSessions</b> -- Maximum number of player sessions allowed for a game session. This value is set when requesting a new game session with <a>CreateGameSession</a> or updating with <a>UpdateGameSession</a>.</p> </li> <li> <p> <b>creationTimeMillis</b> -- Value indicating when a game session was created. It is expressed in Unix time as milliseconds.</p> </li> <li> <p> <b>playerSessionCount</b> -- Number of players currently connected to a game session. This value changes rapidly as players join the session or drop out.</p> </li> <li> <p> <b>hasAvailablePlayerSessions</b> -- Boolean value indicating whether a game session has reached its maximum number of players. It is highly recommended that all search requests include this filter attribute to optimize search performance and return only sessions that players can join. </p> </li> </ul> <note> <p>Returned values for <code>playerSessionCount</code> and <code>hasAvailablePlayerSessions</code> change quickly as players join sessions and others drop out. Results should be considered a snapshot in time. Be sure to refresh search results often, and handle sessions that fill up before a player can join. </p> </note> <p>To search or sort, specify either a fleet ID or an alias ID, and provide a search filter expression, a sort expression, or both. If successful, a collection of <a>GameSession</a> objects matching the request is returned. Use the pagination parameters to retrieve results as a set of sequential pages. </p> <p>You can search for game sessions one fleet at a time only. To find game sessions across multiple fleets, you must search each fleet separately and combine the results. This search feature finds only game sessions that are in <code>ACTIVE</code> status. To locate games in statuses other than active, use <a>DescribeGameSessionDetails</a>.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594841 = header.getOrDefault("X-Amz-Date")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Date", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Security-Token")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Security-Token", valid_594842
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594843 = header.getOrDefault("X-Amz-Target")
  valid_594843 = validateParameter(valid_594843, JString, required = true, default = newJString(
      "GameLift.SearchGameSessions"))
  if valid_594843 != nil:
    section.add "X-Amz-Target", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Content-Sha256", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Algorithm")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Algorithm", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Signature")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Signature", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-SignedHeaders", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Credential")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Credential", valid_594848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594850: Call_SearchGameSessions_594838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all active game sessions that match a set of search criteria and sorts them in a specified order. You can search or sort by the following game session attributes:</p> <ul> <li> <p> <b>gameSessionId</b> -- Unique identifier for the game session. You can use either a <code>GameSessionId</code> or <code>GameSessionArn</code> value. </p> </li> <li> <p> <b>gameSessionName</b> -- Name assigned to a game session. This value is set when requesting a new game session with <a>CreateGameSession</a> or updating with <a>UpdateGameSession</a>. Game session names do not need to be unique to a game session.</p> </li> <li> <p> <b>gameSessionProperties</b> -- Custom data defined in a game session's <code>GameProperty</code> parameter. <code>GameProperty</code> values are stored as key:value pairs; the filter expression must indicate the key and a string to search the data values for. For example, to search for game sessions with custom data containing the key:value pair "gameMode:brawl", specify the following: <code>gameSessionProperties.gameMode = "brawl"</code>. All custom data values are searched as strings.</p> </li> <li> <p> <b>maximumSessions</b> -- Maximum number of player sessions allowed for a game session. This value is set when requesting a new game session with <a>CreateGameSession</a> or updating with <a>UpdateGameSession</a>.</p> </li> <li> <p> <b>creationTimeMillis</b> -- Value indicating when a game session was created. It is expressed in Unix time as milliseconds.</p> </li> <li> <p> <b>playerSessionCount</b> -- Number of players currently connected to a game session. This value changes rapidly as players join the session or drop out.</p> </li> <li> <p> <b>hasAvailablePlayerSessions</b> -- Boolean value indicating whether a game session has reached its maximum number of players. It is highly recommended that all search requests include this filter attribute to optimize search performance and return only sessions that players can join. </p> </li> </ul> <note> <p>Returned values for <code>playerSessionCount</code> and <code>hasAvailablePlayerSessions</code> change quickly as players join sessions and others drop out. Results should be considered a snapshot in time. Be sure to refresh search results often, and handle sessions that fill up before a player can join. </p> </note> <p>To search or sort, specify either a fleet ID or an alias ID, and provide a search filter expression, a sort expression, or both. If successful, a collection of <a>GameSession</a> objects matching the request is returned. Use the pagination parameters to retrieve results as a set of sequential pages. </p> <p>You can search for game sessions one fleet at a time only. To find game sessions across multiple fleets, you must search each fleet separately and combine the results. This search feature finds only game sessions that are in <code>ACTIVE</code> status. To locate games in statuses other than active, use <a>DescribeGameSessionDetails</a>.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594850.validator(path, query, header, formData, body)
  let scheme = call_594850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594850.url(scheme.get, call_594850.host, call_594850.base,
                         call_594850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594850, url, valid)

proc call*(call_594851: Call_SearchGameSessions_594838; body: JsonNode): Recallable =
  ## searchGameSessions
  ## <p>Retrieves all active game sessions that match a set of search criteria and sorts them in a specified order. You can search or sort by the following game session attributes:</p> <ul> <li> <p> <b>gameSessionId</b> -- Unique identifier for the game session. You can use either a <code>GameSessionId</code> or <code>GameSessionArn</code> value. </p> </li> <li> <p> <b>gameSessionName</b> -- Name assigned to a game session. This value is set when requesting a new game session with <a>CreateGameSession</a> or updating with <a>UpdateGameSession</a>. Game session names do not need to be unique to a game session.</p> </li> <li> <p> <b>gameSessionProperties</b> -- Custom data defined in a game session's <code>GameProperty</code> parameter. <code>GameProperty</code> values are stored as key:value pairs; the filter expression must indicate the key and a string to search the data values for. For example, to search for game sessions with custom data containing the key:value pair "gameMode:brawl", specify the following: <code>gameSessionProperties.gameMode = "brawl"</code>. All custom data values are searched as strings.</p> </li> <li> <p> <b>maximumSessions</b> -- Maximum number of player sessions allowed for a game session. This value is set when requesting a new game session with <a>CreateGameSession</a> or updating with <a>UpdateGameSession</a>.</p> </li> <li> <p> <b>creationTimeMillis</b> -- Value indicating when a game session was created. It is expressed in Unix time as milliseconds.</p> </li> <li> <p> <b>playerSessionCount</b> -- Number of players currently connected to a game session. This value changes rapidly as players join the session or drop out.</p> </li> <li> <p> <b>hasAvailablePlayerSessions</b> -- Boolean value indicating whether a game session has reached its maximum number of players. It is highly recommended that all search requests include this filter attribute to optimize search performance and return only sessions that players can join. </p> </li> </ul> <note> <p>Returned values for <code>playerSessionCount</code> and <code>hasAvailablePlayerSessions</code> change quickly as players join sessions and others drop out. Results should be considered a snapshot in time. Be sure to refresh search results often, and handle sessions that fill up before a player can join. </p> </note> <p>To search or sort, specify either a fleet ID or an alias ID, and provide a search filter expression, a sort expression, or both. If successful, a collection of <a>GameSession</a> objects matching the request is returned. Use the pagination parameters to retrieve results as a set of sequential pages. </p> <p>You can search for game sessions one fleet at a time only. To find game sessions across multiple fleets, you must search each fleet separately and combine the results. This search feature finds only game sessions that are in <code>ACTIVE</code> status. To locate games in statuses other than active, use <a>DescribeGameSessionDetails</a>.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594852 = newJObject()
  if body != nil:
    body_594852 = body
  result = call_594851.call(nil, nil, nil, nil, body_594852)

var searchGameSessions* = Call_SearchGameSessions_594838(
    name: "searchGameSessions", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.SearchGameSessions",
    validator: validate_SearchGameSessions_594839, base: "/",
    url: url_SearchGameSessions_594840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFleetActions_594853 = ref object of OpenApiRestCall_593437
proc url_StartFleetActions_594855(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartFleetActions_594854(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Resumes activity on a fleet that was suspended with <a>StopFleetActions</a>. Currently, this operation is used to restart a fleet's auto-scaling activity. </p> <p>To start fleet actions, specify the fleet ID and the type of actions to restart. When auto-scaling fleet actions are restarted, Amazon GameLift once again initiates scaling events as triggered by the fleet's scaling policies. If actions on the fleet were never stopped, this operation will have no effect. You can view a fleet's stopped actions using <a>DescribeFleetAttributes</a>.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594856 = header.getOrDefault("X-Amz-Date")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Date", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Security-Token")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Security-Token", valid_594857
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594858 = header.getOrDefault("X-Amz-Target")
  valid_594858 = validateParameter(valid_594858, JString, required = true, default = newJString(
      "GameLift.StartFleetActions"))
  if valid_594858 != nil:
    section.add "X-Amz-Target", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Content-Sha256", valid_594859
  var valid_594860 = header.getOrDefault("X-Amz-Algorithm")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "X-Amz-Algorithm", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-Signature")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Signature", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-SignedHeaders", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-Credential")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Credential", valid_594863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594865: Call_StartFleetActions_594853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resumes activity on a fleet that was suspended with <a>StopFleetActions</a>. Currently, this operation is used to restart a fleet's auto-scaling activity. </p> <p>To start fleet actions, specify the fleet ID and the type of actions to restart. When auto-scaling fleet actions are restarted, Amazon GameLift once again initiates scaling events as triggered by the fleet's scaling policies. If actions on the fleet were never stopped, this operation will have no effect. You can view a fleet's stopped actions using <a>DescribeFleetAttributes</a>.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594865.validator(path, query, header, formData, body)
  let scheme = call_594865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594865.url(scheme.get, call_594865.host, call_594865.base,
                         call_594865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594865, url, valid)

proc call*(call_594866: Call_StartFleetActions_594853; body: JsonNode): Recallable =
  ## startFleetActions
  ## <p>Resumes activity on a fleet that was suspended with <a>StopFleetActions</a>. Currently, this operation is used to restart a fleet's auto-scaling activity. </p> <p>To start fleet actions, specify the fleet ID and the type of actions to restart. When auto-scaling fleet actions are restarted, Amazon GameLift once again initiates scaling events as triggered by the fleet's scaling policies. If actions on the fleet were never stopped, this operation will have no effect. You can view a fleet's stopped actions using <a>DescribeFleetAttributes</a>.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594867 = newJObject()
  if body != nil:
    body_594867 = body
  result = call_594866.call(nil, nil, nil, nil, body_594867)

var startFleetActions* = Call_StartFleetActions_594853(name: "startFleetActions",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.StartFleetActions",
    validator: validate_StartFleetActions_594854, base: "/",
    url: url_StartFleetActions_594855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartGameSessionPlacement_594868 = ref object of OpenApiRestCall_593437
proc url_StartGameSessionPlacement_594870(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartGameSessionPlacement_594869(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Places a request for a new game session in a queue (see <a>CreateGameSessionQueue</a>). When processing a placement request, Amazon GameLift searches for available resources on the queue's destinations, scanning each until it finds resources or the placement request times out.</p> <p>A game session placement request can also request player sessions. When a new game session is successfully created, Amazon GameLift creates a player session for each player included in the request.</p> <p>When placing a game session, by default Amazon GameLift tries each fleet in the order they are listed in the queue configuration. Ideally, a queue's destinations are listed in preference order.</p> <p>Alternatively, when requesting a game session with players, you can also provide latency data for each player in relevant regions. Latency data indicates the performance lag a player experiences when connected to a fleet in the region. Amazon GameLift uses latency data to reorder the list of destinations to place the game session in a region with minimal lag. If latency data is provided for multiple players, Amazon GameLift calculates each region's average lag for all players and reorders to get the best game play across all players. </p> <p>To place a new game session request, specify the following:</p> <ul> <li> <p>The queue name and a set of game session properties and settings</p> </li> <li> <p>A unique ID (such as a UUID) for the placement. You use this ID to track the status of the placement request</p> </li> <li> <p>(Optional) A set of player data and a unique player ID for each player that you are joining to the new game session (player data is optional, but if you include it, you must also provide a unique ID for each player)</p> </li> <li> <p>Latency data for all players (if you want to optimize game play for the players)</p> </li> </ul> <p>If successful, a new game session placement is created.</p> <p>To track the status of a placement request, call <a>DescribeGameSessionPlacement</a> and check the request's status. If the status is <code>FULFILLED</code>, a new game session has been created and a game session ARN and region are referenced. If the placement request times out, you can resubmit the request or retry it with a different queue. </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594871 = header.getOrDefault("X-Amz-Date")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-Date", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-Security-Token")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Security-Token", valid_594872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594873 = header.getOrDefault("X-Amz-Target")
  valid_594873 = validateParameter(valid_594873, JString, required = true, default = newJString(
      "GameLift.StartGameSessionPlacement"))
  if valid_594873 != nil:
    section.add "X-Amz-Target", valid_594873
  var valid_594874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "X-Amz-Content-Sha256", valid_594874
  var valid_594875 = header.getOrDefault("X-Amz-Algorithm")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Algorithm", valid_594875
  var valid_594876 = header.getOrDefault("X-Amz-Signature")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Signature", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-SignedHeaders", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Credential")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Credential", valid_594878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594880: Call_StartGameSessionPlacement_594868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Places a request for a new game session in a queue (see <a>CreateGameSessionQueue</a>). When processing a placement request, Amazon GameLift searches for available resources on the queue's destinations, scanning each until it finds resources or the placement request times out.</p> <p>A game session placement request can also request player sessions. When a new game session is successfully created, Amazon GameLift creates a player session for each player included in the request.</p> <p>When placing a game session, by default Amazon GameLift tries each fleet in the order they are listed in the queue configuration. Ideally, a queue's destinations are listed in preference order.</p> <p>Alternatively, when requesting a game session with players, you can also provide latency data for each player in relevant regions. Latency data indicates the performance lag a player experiences when connected to a fleet in the region. Amazon GameLift uses latency data to reorder the list of destinations to place the game session in a region with minimal lag. If latency data is provided for multiple players, Amazon GameLift calculates each region's average lag for all players and reorders to get the best game play across all players. </p> <p>To place a new game session request, specify the following:</p> <ul> <li> <p>The queue name and a set of game session properties and settings</p> </li> <li> <p>A unique ID (such as a UUID) for the placement. You use this ID to track the status of the placement request</p> </li> <li> <p>(Optional) A set of player data and a unique player ID for each player that you are joining to the new game session (player data is optional, but if you include it, you must also provide a unique ID for each player)</p> </li> <li> <p>Latency data for all players (if you want to optimize game play for the players)</p> </li> </ul> <p>If successful, a new game session placement is created.</p> <p>To track the status of a placement request, call <a>DescribeGameSessionPlacement</a> and check the request's status. If the status is <code>FULFILLED</code>, a new game session has been created and a game session ARN and region are referenced. If the placement request times out, you can resubmit the request or retry it with a different queue. </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594880.validator(path, query, header, formData, body)
  let scheme = call_594880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594880.url(scheme.get, call_594880.host, call_594880.base,
                         call_594880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594880, url, valid)

proc call*(call_594881: Call_StartGameSessionPlacement_594868; body: JsonNode): Recallable =
  ## startGameSessionPlacement
  ## <p>Places a request for a new game session in a queue (see <a>CreateGameSessionQueue</a>). When processing a placement request, Amazon GameLift searches for available resources on the queue's destinations, scanning each until it finds resources or the placement request times out.</p> <p>A game session placement request can also request player sessions. When a new game session is successfully created, Amazon GameLift creates a player session for each player included in the request.</p> <p>When placing a game session, by default Amazon GameLift tries each fleet in the order they are listed in the queue configuration. Ideally, a queue's destinations are listed in preference order.</p> <p>Alternatively, when requesting a game session with players, you can also provide latency data for each player in relevant regions. Latency data indicates the performance lag a player experiences when connected to a fleet in the region. Amazon GameLift uses latency data to reorder the list of destinations to place the game session in a region with minimal lag. If latency data is provided for multiple players, Amazon GameLift calculates each region's average lag for all players and reorders to get the best game play across all players. </p> <p>To place a new game session request, specify the following:</p> <ul> <li> <p>The queue name and a set of game session properties and settings</p> </li> <li> <p>A unique ID (such as a UUID) for the placement. You use this ID to track the status of the placement request</p> </li> <li> <p>(Optional) A set of player data and a unique player ID for each player that you are joining to the new game session (player data is optional, but if you include it, you must also provide a unique ID for each player)</p> </li> <li> <p>Latency data for all players (if you want to optimize game play for the players)</p> </li> </ul> <p>If successful, a new game session placement is created.</p> <p>To track the status of a placement request, call <a>DescribeGameSessionPlacement</a> and check the request's status. If the status is <code>FULFILLED</code>, a new game session has been created and a game session ARN and region are referenced. If the placement request times out, you can resubmit the request or retry it with a different queue. </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594882 = newJObject()
  if body != nil:
    body_594882 = body
  result = call_594881.call(nil, nil, nil, nil, body_594882)

var startGameSessionPlacement* = Call_StartGameSessionPlacement_594868(
    name: "startGameSessionPlacement", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.StartGameSessionPlacement",
    validator: validate_StartGameSessionPlacement_594869, base: "/",
    url: url_StartGameSessionPlacement_594870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMatchBackfill_594883 = ref object of OpenApiRestCall_593437
proc url_StartMatchBackfill_594885(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMatchBackfill_594884(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Finds new players to fill open slots in an existing game session. This operation can be used to add players to matched games that start with fewer than the maximum number of players or to replace players when they drop out. By backfilling with the same matchmaker used to create the original match, you ensure that new players meet the match criteria and maintain a consistent experience throughout the game session. You can backfill a match anytime after a game session has been created. </p> <p>To request a match backfill, specify a unique ticket ID, the existing game session's ARN, a matchmaking configuration, and a set of data that describes all current players in the game session. If successful, a match backfill ticket is created and returned with status set to QUEUED. The ticket is placed in the matchmaker's ticket pool and processed. Track the status of the ticket to respond as needed. </p> <p>The process of finding backfill matches is essentially identical to the initial matchmaking process. The matchmaker searches the pool and groups tickets together to form potential matches, allowing only one backfill ticket per potential match. Once the a match is formed, the matchmaker creates player sessions for the new players. All tickets in the match are updated with the game session's connection information, and the <a>GameSession</a> object is updated to include matchmaker data on the new players. For more detail on how match backfill requests are processed, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How Amazon GameLift FlexMatch Works</a>. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-backfill.html"> Backfill Existing Games with FlexMatch</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How GameLift FlexMatch Works</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
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
  var valid_594886 = header.getOrDefault("X-Amz-Date")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Date", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Security-Token")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Security-Token", valid_594887
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594888 = header.getOrDefault("X-Amz-Target")
  valid_594888 = validateParameter(valid_594888, JString, required = true, default = newJString(
      "GameLift.StartMatchBackfill"))
  if valid_594888 != nil:
    section.add "X-Amz-Target", valid_594888
  var valid_594889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "X-Amz-Content-Sha256", valid_594889
  var valid_594890 = header.getOrDefault("X-Amz-Algorithm")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Algorithm", valid_594890
  var valid_594891 = header.getOrDefault("X-Amz-Signature")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Signature", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-SignedHeaders", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Credential")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Credential", valid_594893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594895: Call_StartMatchBackfill_594883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds new players to fill open slots in an existing game session. This operation can be used to add players to matched games that start with fewer than the maximum number of players or to replace players when they drop out. By backfilling with the same matchmaker used to create the original match, you ensure that new players meet the match criteria and maintain a consistent experience throughout the game session. You can backfill a match anytime after a game session has been created. </p> <p>To request a match backfill, specify a unique ticket ID, the existing game session's ARN, a matchmaking configuration, and a set of data that describes all current players in the game session. If successful, a match backfill ticket is created and returned with status set to QUEUED. The ticket is placed in the matchmaker's ticket pool and processed. Track the status of the ticket to respond as needed. </p> <p>The process of finding backfill matches is essentially identical to the initial matchmaking process. The matchmaker searches the pool and groups tickets together to form potential matches, allowing only one backfill ticket per potential match. Once the a match is formed, the matchmaker creates player sessions for the new players. All tickets in the match are updated with the game session's connection information, and the <a>GameSession</a> object is updated to include matchmaker data on the new players. For more detail on how match backfill requests are processed, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How Amazon GameLift FlexMatch Works</a>. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-backfill.html"> Backfill Existing Games with FlexMatch</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How GameLift FlexMatch Works</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ## 
  let valid = call_594895.validator(path, query, header, formData, body)
  let scheme = call_594895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594895.url(scheme.get, call_594895.host, call_594895.base,
                         call_594895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594895, url, valid)

proc call*(call_594896: Call_StartMatchBackfill_594883; body: JsonNode): Recallable =
  ## startMatchBackfill
  ## <p>Finds new players to fill open slots in an existing game session. This operation can be used to add players to matched games that start with fewer than the maximum number of players or to replace players when they drop out. By backfilling with the same matchmaker used to create the original match, you ensure that new players meet the match criteria and maintain a consistent experience throughout the game session. You can backfill a match anytime after a game session has been created. </p> <p>To request a match backfill, specify a unique ticket ID, the existing game session's ARN, a matchmaking configuration, and a set of data that describes all current players in the game session. If successful, a match backfill ticket is created and returned with status set to QUEUED. The ticket is placed in the matchmaker's ticket pool and processed. Track the status of the ticket to respond as needed. </p> <p>The process of finding backfill matches is essentially identical to the initial matchmaking process. The matchmaker searches the pool and groups tickets together to form potential matches, allowing only one backfill ticket per potential match. Once the a match is formed, the matchmaker creates player sessions for the new players. All tickets in the match are updated with the game session's connection information, and the <a>GameSession</a> object is updated to include matchmaker data on the new players. For more detail on how match backfill requests are processed, see <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How Amazon GameLift FlexMatch Works</a>. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-backfill.html"> Backfill Existing Games with FlexMatch</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How GameLift FlexMatch Works</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594897 = newJObject()
  if body != nil:
    body_594897 = body
  result = call_594896.call(nil, nil, nil, nil, body_594897)

var startMatchBackfill* = Call_StartMatchBackfill_594883(
    name: "startMatchBackfill", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.StartMatchBackfill",
    validator: validate_StartMatchBackfill_594884, base: "/",
    url: url_StartMatchBackfill_594885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMatchmaking_594898 = ref object of OpenApiRestCall_593437
proc url_StartMatchmaking_594900(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartMatchmaking_594899(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Uses FlexMatch to create a game match for a group of players based on custom matchmaking rules, and starts a new game for the matched players. Each matchmaking request specifies the type of match to build (team configuration, rules for an acceptable match, etc.). The request also specifies the players to find a match for and where to host the new game session for optimal performance. A matchmaking request might start with a single player or a group of players who want to play together. FlexMatch finds additional players as needed to fill the match. Match type, rules, and the queue used to place a new game session are defined in a <code>MatchmakingConfiguration</code>. </p> <p>To start matchmaking, provide a unique ticket ID, specify a matchmaking configuration, and include the players to be matched. You must also include a set of player attributes relevant for the matchmaking configuration. If successful, a matchmaking ticket is returned with status set to <code>QUEUED</code>. Track the status of the ticket to respond as needed and acquire game session connection information for successfully completed matches.</p> <p> <b>Tracking ticket status</b> -- A couple of options are available for tracking the status of matchmaking requests: </p> <ul> <li> <p>Polling -- Call <code>DescribeMatchmaking</code>. This operation returns the full ticket object, including current status and (for completed tickets) game session connection info. We recommend polling no more than once every 10 seconds.</p> </li> <li> <p>Notifications -- Get event notifications for changes in ticket status using Amazon Simple Notification Service (SNS). Notifications are easy to set up (see <a>CreateMatchmakingConfiguration</a>) and typically deliver match status changes faster and more efficiently than polling. We recommend that you use polling to back up to notifications (since delivery is not guaranteed) and call <code>DescribeMatchmaking</code> only when notifications are not received within 30 seconds.</p> </li> </ul> <p> <b>Processing a matchmaking request</b> -- FlexMatch handles a matchmaking request as follows: </p> <ol> <li> <p>Your client code submits a <code>StartMatchmaking</code> request for one or more players and tracks the status of the request ticket. </p> </li> <li> <p>FlexMatch uses this ticket and others in process to build an acceptable match. When a potential match is identified, all tickets in the proposed match are advanced to the next status. </p> </li> <li> <p>If the match requires player acceptance (set in the matchmaking configuration), the tickets move into status <code>REQUIRES_ACCEPTANCE</code>. This status triggers your client code to solicit acceptance from all players in every ticket involved in the match, and then call <a>AcceptMatch</a> for each player. If any player rejects or fails to accept the match before a specified timeout, the proposed match is dropped (see <code>AcceptMatch</code> for more details).</p> </li> <li> <p>Once a match is proposed and accepted, the matchmaking tickets move into status <code>PLACING</code>. FlexMatch locates resources for a new game session using the game session queue (set in the matchmaking configuration) and creates the game session based on the match data. </p> </li> <li> <p>When the match is successfully placed, the matchmaking tickets move into <code>COMPLETED</code> status. Connection information (including game session endpoint and player session) is added to the matchmaking tickets. Matched players can use the connection information to join the game. </p> </li> </ol> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-notification.html"> Set Up FlexMatch Event Notification</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-tasks.html"> FlexMatch Integration Roadmap</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How GameLift FlexMatch Works</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
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
  var valid_594901 = header.getOrDefault("X-Amz-Date")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "X-Amz-Date", valid_594901
  var valid_594902 = header.getOrDefault("X-Amz-Security-Token")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "X-Amz-Security-Token", valid_594902
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594903 = header.getOrDefault("X-Amz-Target")
  valid_594903 = validateParameter(valid_594903, JString, required = true, default = newJString(
      "GameLift.StartMatchmaking"))
  if valid_594903 != nil:
    section.add "X-Amz-Target", valid_594903
  var valid_594904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "X-Amz-Content-Sha256", valid_594904
  var valid_594905 = header.getOrDefault("X-Amz-Algorithm")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Algorithm", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Signature")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Signature", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-SignedHeaders", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Credential")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Credential", valid_594908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594910: Call_StartMatchmaking_594898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uses FlexMatch to create a game match for a group of players based on custom matchmaking rules, and starts a new game for the matched players. Each matchmaking request specifies the type of match to build (team configuration, rules for an acceptable match, etc.). The request also specifies the players to find a match for and where to host the new game session for optimal performance. A matchmaking request might start with a single player or a group of players who want to play together. FlexMatch finds additional players as needed to fill the match. Match type, rules, and the queue used to place a new game session are defined in a <code>MatchmakingConfiguration</code>. </p> <p>To start matchmaking, provide a unique ticket ID, specify a matchmaking configuration, and include the players to be matched. You must also include a set of player attributes relevant for the matchmaking configuration. If successful, a matchmaking ticket is returned with status set to <code>QUEUED</code>. Track the status of the ticket to respond as needed and acquire game session connection information for successfully completed matches.</p> <p> <b>Tracking ticket status</b> -- A couple of options are available for tracking the status of matchmaking requests: </p> <ul> <li> <p>Polling -- Call <code>DescribeMatchmaking</code>. This operation returns the full ticket object, including current status and (for completed tickets) game session connection info. We recommend polling no more than once every 10 seconds.</p> </li> <li> <p>Notifications -- Get event notifications for changes in ticket status using Amazon Simple Notification Service (SNS). Notifications are easy to set up (see <a>CreateMatchmakingConfiguration</a>) and typically deliver match status changes faster and more efficiently than polling. We recommend that you use polling to back up to notifications (since delivery is not guaranteed) and call <code>DescribeMatchmaking</code> only when notifications are not received within 30 seconds.</p> </li> </ul> <p> <b>Processing a matchmaking request</b> -- FlexMatch handles a matchmaking request as follows: </p> <ol> <li> <p>Your client code submits a <code>StartMatchmaking</code> request for one or more players and tracks the status of the request ticket. </p> </li> <li> <p>FlexMatch uses this ticket and others in process to build an acceptable match. When a potential match is identified, all tickets in the proposed match are advanced to the next status. </p> </li> <li> <p>If the match requires player acceptance (set in the matchmaking configuration), the tickets move into status <code>REQUIRES_ACCEPTANCE</code>. This status triggers your client code to solicit acceptance from all players in every ticket involved in the match, and then call <a>AcceptMatch</a> for each player. If any player rejects or fails to accept the match before a specified timeout, the proposed match is dropped (see <code>AcceptMatch</code> for more details).</p> </li> <li> <p>Once a match is proposed and accepted, the matchmaking tickets move into status <code>PLACING</code>. FlexMatch locates resources for a new game session using the game session queue (set in the matchmaking configuration) and creates the game session based on the match data. </p> </li> <li> <p>When the match is successfully placed, the matchmaking tickets move into <code>COMPLETED</code> status. Connection information (including game session endpoint and player session) is added to the matchmaking tickets. Matched players can use the connection information to join the game. </p> </li> </ol> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-notification.html"> Set Up FlexMatch Event Notification</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-tasks.html"> FlexMatch Integration Roadmap</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How GameLift FlexMatch Works</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ## 
  let valid = call_594910.validator(path, query, header, formData, body)
  let scheme = call_594910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594910.url(scheme.get, call_594910.host, call_594910.base,
                         call_594910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594910, url, valid)

proc call*(call_594911: Call_StartMatchmaking_594898; body: JsonNode): Recallable =
  ## startMatchmaking
  ## <p>Uses FlexMatch to create a game match for a group of players based on custom matchmaking rules, and starts a new game for the matched players. Each matchmaking request specifies the type of match to build (team configuration, rules for an acceptable match, etc.). The request also specifies the players to find a match for and where to host the new game session for optimal performance. A matchmaking request might start with a single player or a group of players who want to play together. FlexMatch finds additional players as needed to fill the match. Match type, rules, and the queue used to place a new game session are defined in a <code>MatchmakingConfiguration</code>. </p> <p>To start matchmaking, provide a unique ticket ID, specify a matchmaking configuration, and include the players to be matched. You must also include a set of player attributes relevant for the matchmaking configuration. If successful, a matchmaking ticket is returned with status set to <code>QUEUED</code>. Track the status of the ticket to respond as needed and acquire game session connection information for successfully completed matches.</p> <p> <b>Tracking ticket status</b> -- A couple of options are available for tracking the status of matchmaking requests: </p> <ul> <li> <p>Polling -- Call <code>DescribeMatchmaking</code>. This operation returns the full ticket object, including current status and (for completed tickets) game session connection info. We recommend polling no more than once every 10 seconds.</p> </li> <li> <p>Notifications -- Get event notifications for changes in ticket status using Amazon Simple Notification Service (SNS). Notifications are easy to set up (see <a>CreateMatchmakingConfiguration</a>) and typically deliver match status changes faster and more efficiently than polling. We recommend that you use polling to back up to notifications (since delivery is not guaranteed) and call <code>DescribeMatchmaking</code> only when notifications are not received within 30 seconds.</p> </li> </ul> <p> <b>Processing a matchmaking request</b> -- FlexMatch handles a matchmaking request as follows: </p> <ol> <li> <p>Your client code submits a <code>StartMatchmaking</code> request for one or more players and tracks the status of the request ticket. </p> </li> <li> <p>FlexMatch uses this ticket and others in process to build an acceptable match. When a potential match is identified, all tickets in the proposed match are advanced to the next status. </p> </li> <li> <p>If the match requires player acceptance (set in the matchmaking configuration), the tickets move into status <code>REQUIRES_ACCEPTANCE</code>. This status triggers your client code to solicit acceptance from all players in every ticket involved in the match, and then call <a>AcceptMatch</a> for each player. If any player rejects or fails to accept the match before a specified timeout, the proposed match is dropped (see <code>AcceptMatch</code> for more details).</p> </li> <li> <p>Once a match is proposed and accepted, the matchmaking tickets move into status <code>PLACING</code>. FlexMatch locates resources for a new game session using the game session queue (set in the matchmaking configuration) and creates the game session based on the match data. </p> </li> <li> <p>When the match is successfully placed, the matchmaking tickets move into <code>COMPLETED</code> status. Connection information (including game session endpoint and player session) is added to the matchmaking tickets. Matched players can use the connection information to join the game. </p> </li> </ol> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-notification.html"> Set Up FlexMatch Event Notification</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-tasks.html"> FlexMatch Integration Roadmap</a> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-match.html"> How GameLift FlexMatch Works</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594912 = newJObject()
  if body != nil:
    body_594912 = body
  result = call_594911.call(nil, nil, nil, nil, body_594912)

var startMatchmaking* = Call_StartMatchmaking_594898(name: "startMatchmaking",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.StartMatchmaking",
    validator: validate_StartMatchmaking_594899, base: "/",
    url: url_StartMatchmaking_594900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFleetActions_594913 = ref object of OpenApiRestCall_593437
proc url_StopFleetActions_594915(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopFleetActions_594914(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Suspends activity on a fleet. Currently, this operation is used to stop a fleet's auto-scaling activity. It is used to temporarily stop scaling events triggered by the fleet's scaling policies. The policies can be retained and auto-scaling activity can be restarted using <a>StartFleetActions</a>. You can view a fleet's stopped actions using <a>DescribeFleetAttributes</a>.</p> <p>To stop fleet actions, specify the fleet ID and the type of actions to suspend. When auto-scaling fleet actions are stopped, Amazon GameLift no longer initiates scaling events except to maintain the fleet's desired instances setting (<a>FleetCapacity</a>. Changes to the fleet's capacity must be done manually using <a>UpdateFleetCapacity</a>. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594916 = header.getOrDefault("X-Amz-Date")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-Date", valid_594916
  var valid_594917 = header.getOrDefault("X-Amz-Security-Token")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "X-Amz-Security-Token", valid_594917
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594918 = header.getOrDefault("X-Amz-Target")
  valid_594918 = validateParameter(valid_594918, JString, required = true, default = newJString(
      "GameLift.StopFleetActions"))
  if valid_594918 != nil:
    section.add "X-Amz-Target", valid_594918
  var valid_594919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Content-Sha256", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Algorithm")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Algorithm", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Signature")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Signature", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-SignedHeaders", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Credential")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Credential", valid_594923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594925: Call_StopFleetActions_594913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Suspends activity on a fleet. Currently, this operation is used to stop a fleet's auto-scaling activity. It is used to temporarily stop scaling events triggered by the fleet's scaling policies. The policies can be retained and auto-scaling activity can be restarted using <a>StartFleetActions</a>. You can view a fleet's stopped actions using <a>DescribeFleetAttributes</a>.</p> <p>To stop fleet actions, specify the fleet ID and the type of actions to suspend. When auto-scaling fleet actions are stopped, Amazon GameLift no longer initiates scaling events except to maintain the fleet's desired instances setting (<a>FleetCapacity</a>. Changes to the fleet's capacity must be done manually using <a>UpdateFleetCapacity</a>. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594925.validator(path, query, header, formData, body)
  let scheme = call_594925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594925.url(scheme.get, call_594925.host, call_594925.base,
                         call_594925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594925, url, valid)

proc call*(call_594926: Call_StopFleetActions_594913; body: JsonNode): Recallable =
  ## stopFleetActions
  ## <p>Suspends activity on a fleet. Currently, this operation is used to stop a fleet's auto-scaling activity. It is used to temporarily stop scaling events triggered by the fleet's scaling policies. The policies can be retained and auto-scaling activity can be restarted using <a>StartFleetActions</a>. You can view a fleet's stopped actions using <a>DescribeFleetAttributes</a>.</p> <p>To stop fleet actions, specify the fleet ID and the type of actions to suspend. When auto-scaling fleet actions are stopped, Amazon GameLift no longer initiates scaling events except to maintain the fleet's desired instances setting (<a>FleetCapacity</a>. Changes to the fleet's capacity must be done manually using <a>UpdateFleetCapacity</a>. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594927 = newJObject()
  if body != nil:
    body_594927 = body
  result = call_594926.call(nil, nil, nil, nil, body_594927)

var stopFleetActions* = Call_StopFleetActions_594913(name: "stopFleetActions",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.StopFleetActions",
    validator: validate_StopFleetActions_594914, base: "/",
    url: url_StopFleetActions_594915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopGameSessionPlacement_594928 = ref object of OpenApiRestCall_593437
proc url_StopGameSessionPlacement_594930(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopGameSessionPlacement_594929(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Cancels a game session placement that is in <code>PENDING</code> status. To stop a placement, provide the placement ID values. If successful, the placement is moved to <code>CANCELLED</code> status.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_594931 = header.getOrDefault("X-Amz-Date")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-Date", valid_594931
  var valid_594932 = header.getOrDefault("X-Amz-Security-Token")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "X-Amz-Security-Token", valid_594932
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594933 = header.getOrDefault("X-Amz-Target")
  valid_594933 = validateParameter(valid_594933, JString, required = true, default = newJString(
      "GameLift.StopGameSessionPlacement"))
  if valid_594933 != nil:
    section.add "X-Amz-Target", valid_594933
  var valid_594934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594934 = validateParameter(valid_594934, JString, required = false,
                                 default = nil)
  if valid_594934 != nil:
    section.add "X-Amz-Content-Sha256", valid_594934
  var valid_594935 = header.getOrDefault("X-Amz-Algorithm")
  valid_594935 = validateParameter(valid_594935, JString, required = false,
                                 default = nil)
  if valid_594935 != nil:
    section.add "X-Amz-Algorithm", valid_594935
  var valid_594936 = header.getOrDefault("X-Amz-Signature")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "X-Amz-Signature", valid_594936
  var valid_594937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "X-Amz-SignedHeaders", valid_594937
  var valid_594938 = header.getOrDefault("X-Amz-Credential")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "X-Amz-Credential", valid_594938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594940: Call_StopGameSessionPlacement_594928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a game session placement that is in <code>PENDING</code> status. To stop a placement, provide the placement ID values. If successful, the placement is moved to <code>CANCELLED</code> status.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_594940.validator(path, query, header, formData, body)
  let scheme = call_594940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594940.url(scheme.get, call_594940.host, call_594940.base,
                         call_594940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594940, url, valid)

proc call*(call_594941: Call_StopGameSessionPlacement_594928; body: JsonNode): Recallable =
  ## stopGameSessionPlacement
  ## <p>Cancels a game session placement that is in <code>PENDING</code> status. To stop a placement, provide the placement ID values. If successful, the placement is moved to <code>CANCELLED</code> status.</p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_594942 = newJObject()
  if body != nil:
    body_594942 = body
  result = call_594941.call(nil, nil, nil, nil, body_594942)

var stopGameSessionPlacement* = Call_StopGameSessionPlacement_594928(
    name: "stopGameSessionPlacement", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.StopGameSessionPlacement",
    validator: validate_StopGameSessionPlacement_594929, base: "/",
    url: url_StopGameSessionPlacement_594930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMatchmaking_594943 = ref object of OpenApiRestCall_593437
proc url_StopMatchmaking_594945(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopMatchmaking_594944(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Cancels a matchmaking ticket or match backfill ticket that is currently being processed. To stop the matchmaking operation, specify the ticket ID. If successful, work on the ticket is stopped, and the ticket status is changed to <code>CANCELLED</code>.</p> <p>This call is also used to turn off automatic backfill for an individual game session. This is for game sessions that are created with a matchmaking configuration that has automatic backfill enabled. The ticket ID is included in the <code>MatchmakerData</code> of an updated game session object, which is provided to the game server.</p> <note> <p>If the action is successful, the service sends back an empty JSON struct with the HTTP 200 response (not an empty HTTP body).</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
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
  var valid_594946 = header.getOrDefault("X-Amz-Date")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-Date", valid_594946
  var valid_594947 = header.getOrDefault("X-Amz-Security-Token")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "X-Amz-Security-Token", valid_594947
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594948 = header.getOrDefault("X-Amz-Target")
  valid_594948 = validateParameter(valid_594948, JString, required = true, default = newJString(
      "GameLift.StopMatchmaking"))
  if valid_594948 != nil:
    section.add "X-Amz-Target", valid_594948
  var valid_594949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "X-Amz-Content-Sha256", valid_594949
  var valid_594950 = header.getOrDefault("X-Amz-Algorithm")
  valid_594950 = validateParameter(valid_594950, JString, required = false,
                                 default = nil)
  if valid_594950 != nil:
    section.add "X-Amz-Algorithm", valid_594950
  var valid_594951 = header.getOrDefault("X-Amz-Signature")
  valid_594951 = validateParameter(valid_594951, JString, required = false,
                                 default = nil)
  if valid_594951 != nil:
    section.add "X-Amz-Signature", valid_594951
  var valid_594952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594952 = validateParameter(valid_594952, JString, required = false,
                                 default = nil)
  if valid_594952 != nil:
    section.add "X-Amz-SignedHeaders", valid_594952
  var valid_594953 = header.getOrDefault("X-Amz-Credential")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-Credential", valid_594953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594955: Call_StopMatchmaking_594943; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels a matchmaking ticket or match backfill ticket that is currently being processed. To stop the matchmaking operation, specify the ticket ID. If successful, work on the ticket is stopped, and the ticket status is changed to <code>CANCELLED</code>.</p> <p>This call is also used to turn off automatic backfill for an individual game session. This is for game sessions that are created with a matchmaking configuration that has automatic backfill enabled. The ticket ID is included in the <code>MatchmakerData</code> of an updated game session object, which is provided to the game server.</p> <note> <p>If the action is successful, the service sends back an empty JSON struct with the HTTP 200 response (not an empty HTTP body).</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ## 
  let valid = call_594955.validator(path, query, header, formData, body)
  let scheme = call_594955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594955.url(scheme.get, call_594955.host, call_594955.base,
                         call_594955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594955, url, valid)

proc call*(call_594956: Call_StopMatchmaking_594943; body: JsonNode): Recallable =
  ## stopMatchmaking
  ## <p>Cancels a matchmaking ticket or match backfill ticket that is currently being processed. To stop the matchmaking operation, specify the ticket ID. If successful, work on the ticket is stopped, and the ticket status is changed to <code>CANCELLED</code>.</p> <p>This call is also used to turn off automatic backfill for an individual game session. This is for game sessions that are created with a matchmaking configuration that has automatic backfill enabled. The ticket ID is included in the <code>MatchmakerData</code> of an updated game session object, which is provided to the game server.</p> <note> <p>If the action is successful, the service sends back an empty JSON struct with the HTTP 200 response (not an empty HTTP body).</p> </note> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-client.html"> Add FlexMatch to a Game Client</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>StartMatchmaking</a> </p> </li> <li> <p> <a>DescribeMatchmaking</a> </p> </li> <li> <p> <a>StopMatchmaking</a> </p> </li> <li> <p> <a>AcceptMatch</a> </p> </li> <li> <p> <a>StartMatchBackfill</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594957 = newJObject()
  if body != nil:
    body_594957 = body
  result = call_594956.call(nil, nil, nil, nil, body_594957)

var stopMatchmaking* = Call_StopMatchmaking_594943(name: "stopMatchmaking",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.StopMatchmaking",
    validator: validate_StopMatchmaking_594944, base: "/", url: url_StopMatchmaking_594945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_594958 = ref object of OpenApiRestCall_593437
proc url_UpdateAlias_594960(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAlias_594959(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates properties for an alias. To update properties, specify the alias ID to be updated and provide the information to be changed. To reassign an alias to another fleet, provide an updated routing strategy. If successful, the updated alias record is returned.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
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
  var valid_594961 = header.getOrDefault("X-Amz-Date")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Date", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-Security-Token")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-Security-Token", valid_594962
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594963 = header.getOrDefault("X-Amz-Target")
  valid_594963 = validateParameter(valid_594963, JString, required = true,
                                 default = newJString("GameLift.UpdateAlias"))
  if valid_594963 != nil:
    section.add "X-Amz-Target", valid_594963
  var valid_594964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594964 = validateParameter(valid_594964, JString, required = false,
                                 default = nil)
  if valid_594964 != nil:
    section.add "X-Amz-Content-Sha256", valid_594964
  var valid_594965 = header.getOrDefault("X-Amz-Algorithm")
  valid_594965 = validateParameter(valid_594965, JString, required = false,
                                 default = nil)
  if valid_594965 != nil:
    section.add "X-Amz-Algorithm", valid_594965
  var valid_594966 = header.getOrDefault("X-Amz-Signature")
  valid_594966 = validateParameter(valid_594966, JString, required = false,
                                 default = nil)
  if valid_594966 != nil:
    section.add "X-Amz-Signature", valid_594966
  var valid_594967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594967 = validateParameter(valid_594967, JString, required = false,
                                 default = nil)
  if valid_594967 != nil:
    section.add "X-Amz-SignedHeaders", valid_594967
  var valid_594968 = header.getOrDefault("X-Amz-Credential")
  valid_594968 = validateParameter(valid_594968, JString, required = false,
                                 default = nil)
  if valid_594968 != nil:
    section.add "X-Amz-Credential", valid_594968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594970: Call_UpdateAlias_594958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates properties for an alias. To update properties, specify the alias ID to be updated and provide the information to be changed. To reassign an alias to another fleet, provide an updated routing strategy. If successful, the updated alias record is returned.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ## 
  let valid = call_594970.validator(path, query, header, formData, body)
  let scheme = call_594970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594970.url(scheme.get, call_594970.host, call_594970.base,
                         call_594970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594970, url, valid)

proc call*(call_594971: Call_UpdateAlias_594958; body: JsonNode): Recallable =
  ## updateAlias
  ## <p>Updates properties for an alias. To update properties, specify the alias ID to be updated and provide the information to be changed. To reassign an alias to another fleet, provide an updated routing strategy. If successful, the updated alias record is returned.</p> <ul> <li> <p> <a>CreateAlias</a> </p> </li> <li> <p> <a>ListAliases</a> </p> </li> <li> <p> <a>DescribeAlias</a> </p> </li> <li> <p> <a>UpdateAlias</a> </p> </li> <li> <p> <a>DeleteAlias</a> </p> </li> <li> <p> <a>ResolveAlias</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594972 = newJObject()
  if body != nil:
    body_594972 = body
  result = call_594971.call(nil, nil, nil, nil, body_594972)

var updateAlias* = Call_UpdateAlias_594958(name: "updateAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.UpdateAlias",
                                        validator: validate_UpdateAlias_594959,
                                        base: "/", url: url_UpdateAlias_594960,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBuild_594973 = ref object of OpenApiRestCall_593437
proc url_UpdateBuild_594975(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateBuild_594974(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates metadata in a build record, including the build name and version. To update the metadata, specify the build ID to update and provide the new values. If successful, a build object containing the updated metadata is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
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
  var valid_594976 = header.getOrDefault("X-Amz-Date")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Date", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-Security-Token")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-Security-Token", valid_594977
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594978 = header.getOrDefault("X-Amz-Target")
  valid_594978 = validateParameter(valid_594978, JString, required = true,
                                 default = newJString("GameLift.UpdateBuild"))
  if valid_594978 != nil:
    section.add "X-Amz-Target", valid_594978
  var valid_594979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "X-Amz-Content-Sha256", valid_594979
  var valid_594980 = header.getOrDefault("X-Amz-Algorithm")
  valid_594980 = validateParameter(valid_594980, JString, required = false,
                                 default = nil)
  if valid_594980 != nil:
    section.add "X-Amz-Algorithm", valid_594980
  var valid_594981 = header.getOrDefault("X-Amz-Signature")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-Signature", valid_594981
  var valid_594982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594982 = validateParameter(valid_594982, JString, required = false,
                                 default = nil)
  if valid_594982 != nil:
    section.add "X-Amz-SignedHeaders", valid_594982
  var valid_594983 = header.getOrDefault("X-Amz-Credential")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "X-Amz-Credential", valid_594983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594985: Call_UpdateBuild_594973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates metadata in a build record, including the build name and version. To update the metadata, specify the build ID to update and provide the new values. If successful, a build object containing the updated metadata is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ## 
  let valid = call_594985.validator(path, query, header, formData, body)
  let scheme = call_594985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594985.url(scheme.get, call_594985.host, call_594985.base,
                         call_594985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594985, url, valid)

proc call*(call_594986: Call_UpdateBuild_594973; body: JsonNode): Recallable =
  ## updateBuild
  ## <p>Updates metadata in a build record, including the build name and version. To update the metadata, specify the build ID to update and provide the new values. If successful, a build object containing the updated metadata is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/build-intro.html"> Working with Builds</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateBuild</a> </p> </li> <li> <p> <a>ListBuilds</a> </p> </li> <li> <p> <a>DescribeBuild</a> </p> </li> <li> <p> <a>UpdateBuild</a> </p> </li> <li> <p> <a>DeleteBuild</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_594987 = newJObject()
  if body != nil:
    body_594987 = body
  result = call_594986.call(nil, nil, nil, nil, body_594987)

var updateBuild* = Call_UpdateBuild_594973(name: "updateBuild",
                                        meth: HttpMethod.HttpPost,
                                        host: "gamelift.amazonaws.com", route: "/#X-Amz-Target=GameLift.UpdateBuild",
                                        validator: validate_UpdateBuild_594974,
                                        base: "/", url: url_UpdateBuild_594975,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetAttributes_594988 = ref object of OpenApiRestCall_593437
proc url_UpdateFleetAttributes_594990(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFleetAttributes_594989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates fleet properties, including name and description, for a fleet. To update metadata, specify the fleet ID and the property values that you want to change. If successful, the fleet ID for the updated fleet is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_594991 = header.getOrDefault("X-Amz-Date")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Date", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-Security-Token")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Security-Token", valid_594992
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594993 = header.getOrDefault("X-Amz-Target")
  valid_594993 = validateParameter(valid_594993, JString, required = true, default = newJString(
      "GameLift.UpdateFleetAttributes"))
  if valid_594993 != nil:
    section.add "X-Amz-Target", valid_594993
  var valid_594994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-Content-Sha256", valid_594994
  var valid_594995 = header.getOrDefault("X-Amz-Algorithm")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "X-Amz-Algorithm", valid_594995
  var valid_594996 = header.getOrDefault("X-Amz-Signature")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Signature", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-SignedHeaders", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Credential")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Credential", valid_594998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595000: Call_UpdateFleetAttributes_594988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates fleet properties, including name and description, for a fleet. To update metadata, specify the fleet ID and the property values that you want to change. If successful, the fleet ID for the updated fleet is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_595000.validator(path, query, header, formData, body)
  let scheme = call_595000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595000.url(scheme.get, call_595000.host, call_595000.base,
                         call_595000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595000, url, valid)

proc call*(call_595001: Call_UpdateFleetAttributes_594988; body: JsonNode): Recallable =
  ## updateFleetAttributes
  ## <p>Updates fleet properties, including name and description, for a fleet. To update metadata, specify the fleet ID and the property values that you want to change. If successful, the fleet ID for the updated fleet is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_595002 = newJObject()
  if body != nil:
    body_595002 = body
  result = call_595001.call(nil, nil, nil, nil, body_595002)

var updateFleetAttributes* = Call_UpdateFleetAttributes_594988(
    name: "updateFleetAttributes", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateFleetAttributes",
    validator: validate_UpdateFleetAttributes_594989, base: "/",
    url: url_UpdateFleetAttributes_594990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetCapacity_595003 = ref object of OpenApiRestCall_593437
proc url_UpdateFleetCapacity_595005(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFleetCapacity_595004(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Updates capacity settings for a fleet. Use this action to specify the number of EC2 instances (hosts) that you want this fleet to contain. Before calling this action, you may want to call <a>DescribeEC2InstanceLimits</a> to get the maximum capacity based on the fleet's EC2 instance type.</p> <p>Specify minimum and maximum number of instances. Amazon GameLift will not change fleet capacity to values fall outside of this range. This is particularly important when using auto-scaling (see <a>PutScalingPolicy</a>) to allow capacity to adjust based on player demand while imposing limits on automatic adjustments.</p> <p>To update fleet capacity, specify the fleet ID and the number of instances you want the fleet to host. If successful, Amazon GameLift starts or terminates instances so that the fleet's active instance count matches the desired instance count. You can view a fleet's current capacity information by calling <a>DescribeFleetCapacity</a>. If the desired instance count is higher than the instance type's limit, the "Limit Exceeded" exception occurs.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_595006 = header.getOrDefault("X-Amz-Date")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Date", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Security-Token")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Security-Token", valid_595007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595008 = header.getOrDefault("X-Amz-Target")
  valid_595008 = validateParameter(valid_595008, JString, required = true, default = newJString(
      "GameLift.UpdateFleetCapacity"))
  if valid_595008 != nil:
    section.add "X-Amz-Target", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Content-Sha256", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-Algorithm")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-Algorithm", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Signature")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Signature", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-SignedHeaders", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Credential")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Credential", valid_595013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595015: Call_UpdateFleetCapacity_595003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates capacity settings for a fleet. Use this action to specify the number of EC2 instances (hosts) that you want this fleet to contain. Before calling this action, you may want to call <a>DescribeEC2InstanceLimits</a> to get the maximum capacity based on the fleet's EC2 instance type.</p> <p>Specify minimum and maximum number of instances. Amazon GameLift will not change fleet capacity to values fall outside of this range. This is particularly important when using auto-scaling (see <a>PutScalingPolicy</a>) to allow capacity to adjust based on player demand while imposing limits on automatic adjustments.</p> <p>To update fleet capacity, specify the fleet ID and the number of instances you want the fleet to host. If successful, Amazon GameLift starts or terminates instances so that the fleet's active instance count matches the desired instance count. You can view a fleet's current capacity information by calling <a>DescribeFleetCapacity</a>. If the desired instance count is higher than the instance type's limit, the "Limit Exceeded" exception occurs.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_595015.validator(path, query, header, formData, body)
  let scheme = call_595015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595015.url(scheme.get, call_595015.host, call_595015.base,
                         call_595015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595015, url, valid)

proc call*(call_595016: Call_UpdateFleetCapacity_595003; body: JsonNode): Recallable =
  ## updateFleetCapacity
  ## <p>Updates capacity settings for a fleet. Use this action to specify the number of EC2 instances (hosts) that you want this fleet to contain. Before calling this action, you may want to call <a>DescribeEC2InstanceLimits</a> to get the maximum capacity based on the fleet's EC2 instance type.</p> <p>Specify minimum and maximum number of instances. Amazon GameLift will not change fleet capacity to values fall outside of this range. This is particularly important when using auto-scaling (see <a>PutScalingPolicy</a>) to allow capacity to adjust based on player demand while imposing limits on automatic adjustments.</p> <p>To update fleet capacity, specify the fleet ID and the number of instances you want the fleet to host. If successful, Amazon GameLift starts or terminates instances so that the fleet's active instance count matches the desired instance count. You can view a fleet's current capacity information by calling <a>DescribeFleetCapacity</a>. If the desired instance count is higher than the instance type's limit, the "Limit Exceeded" exception occurs.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_595017 = newJObject()
  if body != nil:
    body_595017 = body
  result = call_595016.call(nil, nil, nil, nil, body_595017)

var updateFleetCapacity* = Call_UpdateFleetCapacity_595003(
    name: "updateFleetCapacity", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateFleetCapacity",
    validator: validate_UpdateFleetCapacity_595004, base: "/",
    url: url_UpdateFleetCapacity_595005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFleetPortSettings_595018 = ref object of OpenApiRestCall_593437
proc url_UpdateFleetPortSettings_595020(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateFleetPortSettings_595019(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates port settings for a fleet. To update settings, specify the fleet ID to be updated and list the permissions you want to update. List the permissions you want to add in <code>InboundPermissionAuthorizations</code>, and permissions you want to remove in <code>InboundPermissionRevocations</code>. Permissions to be removed must match existing fleet permissions. If successful, the fleet ID for the updated fleet is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_595021 = header.getOrDefault("X-Amz-Date")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Date", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-Security-Token")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-Security-Token", valid_595022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595023 = header.getOrDefault("X-Amz-Target")
  valid_595023 = validateParameter(valid_595023, JString, required = true, default = newJString(
      "GameLift.UpdateFleetPortSettings"))
  if valid_595023 != nil:
    section.add "X-Amz-Target", valid_595023
  var valid_595024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "X-Amz-Content-Sha256", valid_595024
  var valid_595025 = header.getOrDefault("X-Amz-Algorithm")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "X-Amz-Algorithm", valid_595025
  var valid_595026 = header.getOrDefault("X-Amz-Signature")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "X-Amz-Signature", valid_595026
  var valid_595027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "X-Amz-SignedHeaders", valid_595027
  var valid_595028 = header.getOrDefault("X-Amz-Credential")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "X-Amz-Credential", valid_595028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595030: Call_UpdateFleetPortSettings_595018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates port settings for a fleet. To update settings, specify the fleet ID to be updated and list the permissions you want to update. List the permissions you want to add in <code>InboundPermissionAuthorizations</code>, and permissions you want to remove in <code>InboundPermissionRevocations</code>. Permissions to be removed must match existing fleet permissions. If successful, the fleet ID for the updated fleet is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_595030.validator(path, query, header, formData, body)
  let scheme = call_595030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595030.url(scheme.get, call_595030.host, call_595030.base,
                         call_595030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595030, url, valid)

proc call*(call_595031: Call_UpdateFleetPortSettings_595018; body: JsonNode): Recallable =
  ## updateFleetPortSettings
  ## <p>Updates port settings for a fleet. To update settings, specify the fleet ID to be updated and list the permissions you want to update. List the permissions you want to add in <code>InboundPermissionAuthorizations</code>, and permissions you want to remove in <code>InboundPermissionRevocations</code>. Permissions to be removed must match existing fleet permissions. If successful, the fleet ID for the updated fleet is returned.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_595032 = newJObject()
  if body != nil:
    body_595032 = body
  result = call_595031.call(nil, nil, nil, nil, body_595032)

var updateFleetPortSettings* = Call_UpdateFleetPortSettings_595018(
    name: "updateFleetPortSettings", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateFleetPortSettings",
    validator: validate_UpdateFleetPortSettings_595019, base: "/",
    url: url_UpdateFleetPortSettings_595020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGameSession_595033 = ref object of OpenApiRestCall_593437
proc url_UpdateGameSession_595035(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGameSession_595034(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates game session properties. This includes the session name, maximum player count, protection policy, which controls whether or not an active game session can be terminated during a scale-down event, and the player session creation policy, which controls whether or not new players can join the session. To update a game session, specify the game session ID and the values you want to change. If successful, an updated <a>GameSession</a> object is returned. </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
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
  var valid_595036 = header.getOrDefault("X-Amz-Date")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Date", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-Security-Token")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-Security-Token", valid_595037
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595038 = header.getOrDefault("X-Amz-Target")
  valid_595038 = validateParameter(valid_595038, JString, required = true, default = newJString(
      "GameLift.UpdateGameSession"))
  if valid_595038 != nil:
    section.add "X-Amz-Target", valid_595038
  var valid_595039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595039 = validateParameter(valid_595039, JString, required = false,
                                 default = nil)
  if valid_595039 != nil:
    section.add "X-Amz-Content-Sha256", valid_595039
  var valid_595040 = header.getOrDefault("X-Amz-Algorithm")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "X-Amz-Algorithm", valid_595040
  var valid_595041 = header.getOrDefault("X-Amz-Signature")
  valid_595041 = validateParameter(valid_595041, JString, required = false,
                                 default = nil)
  if valid_595041 != nil:
    section.add "X-Amz-Signature", valid_595041
  var valid_595042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "X-Amz-SignedHeaders", valid_595042
  var valid_595043 = header.getOrDefault("X-Amz-Credential")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "X-Amz-Credential", valid_595043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595045: Call_UpdateGameSession_595033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates game session properties. This includes the session name, maximum player count, protection policy, which controls whether or not an active game session can be terminated during a scale-down event, and the player session creation policy, which controls whether or not new players can join the session. To update a game session, specify the game session ID and the values you want to change. If successful, an updated <a>GameSession</a> object is returned. </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_595045.validator(path, query, header, formData, body)
  let scheme = call_595045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595045.url(scheme.get, call_595045.host, call_595045.base,
                         call_595045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595045, url, valid)

proc call*(call_595046: Call_UpdateGameSession_595033; body: JsonNode): Recallable =
  ## updateGameSession
  ## <p>Updates game session properties. This includes the session name, maximum player count, protection policy, which controls whether or not an active game session can be terminated during a scale-down event, and the player session creation policy, which controls whether or not new players can join the session. To update a game session, specify the game session ID and the values you want to change. If successful, an updated <a>GameSession</a> object is returned. </p> <ul> <li> <p> <a>CreateGameSession</a> </p> </li> <li> <p> <a>DescribeGameSessions</a> </p> </li> <li> <p> <a>DescribeGameSessionDetails</a> </p> </li> <li> <p> <a>SearchGameSessions</a> </p> </li> <li> <p> <a>UpdateGameSession</a> </p> </li> <li> <p> <a>GetGameSessionLogUrl</a> </p> </li> <li> <p>Game session placements</p> <ul> <li> <p> <a>StartGameSessionPlacement</a> </p> </li> <li> <p> <a>DescribeGameSessionPlacement</a> </p> </li> <li> <p> <a>StopGameSessionPlacement</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_595047 = newJObject()
  if body != nil:
    body_595047 = body
  result = call_595046.call(nil, nil, nil, nil, body_595047)

var updateGameSession* = Call_UpdateGameSession_595033(name: "updateGameSession",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateGameSession",
    validator: validate_UpdateGameSession_595034, base: "/",
    url: url_UpdateGameSession_595035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGameSessionQueue_595048 = ref object of OpenApiRestCall_593437
proc url_UpdateGameSessionQueue_595050(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGameSessionQueue_595049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates settings for a game session queue, which determines how new game session requests in the queue are processed. To update settings, specify the queue name to be updated and provide the new settings. When updating destinations, provide a complete list of destinations. </p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
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
  var valid_595051 = header.getOrDefault("X-Amz-Date")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Date", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-Security-Token")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Security-Token", valid_595052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595053 = header.getOrDefault("X-Amz-Target")
  valid_595053 = validateParameter(valid_595053, JString, required = true, default = newJString(
      "GameLift.UpdateGameSessionQueue"))
  if valid_595053 != nil:
    section.add "X-Amz-Target", valid_595053
  var valid_595054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "X-Amz-Content-Sha256", valid_595054
  var valid_595055 = header.getOrDefault("X-Amz-Algorithm")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "X-Amz-Algorithm", valid_595055
  var valid_595056 = header.getOrDefault("X-Amz-Signature")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = nil)
  if valid_595056 != nil:
    section.add "X-Amz-Signature", valid_595056
  var valid_595057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "X-Amz-SignedHeaders", valid_595057
  var valid_595058 = header.getOrDefault("X-Amz-Credential")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "X-Amz-Credential", valid_595058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595060: Call_UpdateGameSessionQueue_595048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates settings for a game session queue, which determines how new game session requests in the queue are processed. To update settings, specify the queue name to be updated and provide the new settings. When updating destinations, provide a complete list of destinations. </p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ## 
  let valid = call_595060.validator(path, query, header, formData, body)
  let scheme = call_595060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595060.url(scheme.get, call_595060.host, call_595060.base,
                         call_595060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595060, url, valid)

proc call*(call_595061: Call_UpdateGameSessionQueue_595048; body: JsonNode): Recallable =
  ## updateGameSessionQueue
  ## <p>Updates settings for a game session queue, which determines how new game session requests in the queue are processed. To update settings, specify the queue name to be updated and provide the new settings. When updating destinations, provide a complete list of destinations. </p> <ul> <li> <p> <a>CreateGameSessionQueue</a> </p> </li> <li> <p> <a>DescribeGameSessionQueues</a> </p> </li> <li> <p> <a>UpdateGameSessionQueue</a> </p> </li> <li> <p> <a>DeleteGameSessionQueue</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_595062 = newJObject()
  if body != nil:
    body_595062 = body
  result = call_595061.call(nil, nil, nil, nil, body_595062)

var updateGameSessionQueue* = Call_UpdateGameSessionQueue_595048(
    name: "updateGameSessionQueue", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateGameSessionQueue",
    validator: validate_UpdateGameSessionQueue_595049, base: "/",
    url: url_UpdateGameSessionQueue_595050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMatchmakingConfiguration_595063 = ref object of OpenApiRestCall_593437
proc url_UpdateMatchmakingConfiguration_595065(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMatchmakingConfiguration_595064(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates settings for a FlexMatch matchmaking configuration. These changes affect all matches and game sessions that are created after the update. To update settings, specify the configuration name to be updated and provide the new settings. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html"> Design a FlexMatch Matchmaker</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_595066 = header.getOrDefault("X-Amz-Date")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Date", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-Security-Token")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-Security-Token", valid_595067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595068 = header.getOrDefault("X-Amz-Target")
  valid_595068 = validateParameter(valid_595068, JString, required = true, default = newJString(
      "GameLift.UpdateMatchmakingConfiguration"))
  if valid_595068 != nil:
    section.add "X-Amz-Target", valid_595068
  var valid_595069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-Content-Sha256", valid_595069
  var valid_595070 = header.getOrDefault("X-Amz-Algorithm")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Algorithm", valid_595070
  var valid_595071 = header.getOrDefault("X-Amz-Signature")
  valid_595071 = validateParameter(valid_595071, JString, required = false,
                                 default = nil)
  if valid_595071 != nil:
    section.add "X-Amz-Signature", valid_595071
  var valid_595072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-SignedHeaders", valid_595072
  var valid_595073 = header.getOrDefault("X-Amz-Credential")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "X-Amz-Credential", valid_595073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595075: Call_UpdateMatchmakingConfiguration_595063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates settings for a FlexMatch matchmaking configuration. These changes affect all matches and game sessions that are created after the update. To update settings, specify the configuration name to be updated and provide the new settings. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html"> Design a FlexMatch Matchmaker</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_595075.validator(path, query, header, formData, body)
  let scheme = call_595075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595075.url(scheme.get, call_595075.host, call_595075.base,
                         call_595075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595075, url, valid)

proc call*(call_595076: Call_UpdateMatchmakingConfiguration_595063; body: JsonNode): Recallable =
  ## updateMatchmakingConfiguration
  ## <p>Updates settings for a FlexMatch matchmaking configuration. These changes affect all matches and game sessions that are created after the update. To update settings, specify the configuration name to be updated and provide the new settings. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-configuration.html"> Design a FlexMatch Matchmaker</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_595077 = newJObject()
  if body != nil:
    body_595077 = body
  result = call_595076.call(nil, nil, nil, nil, body_595077)

var updateMatchmakingConfiguration* = Call_UpdateMatchmakingConfiguration_595063(
    name: "updateMatchmakingConfiguration", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateMatchmakingConfiguration",
    validator: validate_UpdateMatchmakingConfiguration_595064, base: "/",
    url: url_UpdateMatchmakingConfiguration_595065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuntimeConfiguration_595078 = ref object of OpenApiRestCall_593437
proc url_UpdateRuntimeConfiguration_595080(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRuntimeConfiguration_595079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the current run-time configuration for the specified fleet, which tells Amazon GameLift how to launch server processes on instances in the fleet. You can update a fleet's run-time configuration at any time after the fleet is created; it does not need to be in an <code>ACTIVE</code> status.</p> <p>To update run-time configuration, specify the fleet ID and provide a <code>RuntimeConfiguration</code> object with an updated set of server process configurations.</p> <p>Each instance in a Amazon GameLift fleet checks regularly for an updated run-time configuration and changes how it launches server processes to comply with the latest version. Existing server processes are not affected by the update; run-time configuration changes are applied gradually as existing processes shut down and new processes are launched during Amazon GameLift's normal process recycling activity.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
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
  var valid_595081 = header.getOrDefault("X-Amz-Date")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Date", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Security-Token")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Security-Token", valid_595082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595083 = header.getOrDefault("X-Amz-Target")
  valid_595083 = validateParameter(valid_595083, JString, required = true, default = newJString(
      "GameLift.UpdateRuntimeConfiguration"))
  if valid_595083 != nil:
    section.add "X-Amz-Target", valid_595083
  var valid_595084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-Content-Sha256", valid_595084
  var valid_595085 = header.getOrDefault("X-Amz-Algorithm")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Algorithm", valid_595085
  var valid_595086 = header.getOrDefault("X-Amz-Signature")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-Signature", valid_595086
  var valid_595087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-SignedHeaders", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Credential")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Credential", valid_595088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595090: Call_UpdateRuntimeConfiguration_595078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the current run-time configuration for the specified fleet, which tells Amazon GameLift how to launch server processes on instances in the fleet. You can update a fleet's run-time configuration at any time after the fleet is created; it does not need to be in an <code>ACTIVE</code> status.</p> <p>To update run-time configuration, specify the fleet ID and provide a <code>RuntimeConfiguration</code> object with an updated set of server process configurations.</p> <p>Each instance in a Amazon GameLift fleet checks regularly for an updated run-time configuration and changes how it launches server processes to comply with the latest version. Existing server processes are not affected by the update; run-time configuration changes are applied gradually as existing processes shut down and new processes are launched during Amazon GameLift's normal process recycling activity.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ## 
  let valid = call_595090.validator(path, query, header, formData, body)
  let scheme = call_595090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595090.url(scheme.get, call_595090.host, call_595090.base,
                         call_595090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595090, url, valid)

proc call*(call_595091: Call_UpdateRuntimeConfiguration_595078; body: JsonNode): Recallable =
  ## updateRuntimeConfiguration
  ## <p>Updates the current run-time configuration for the specified fleet, which tells Amazon GameLift how to launch server processes on instances in the fleet. You can update a fleet's run-time configuration at any time after the fleet is created; it does not need to be in an <code>ACTIVE</code> status.</p> <p>To update run-time configuration, specify the fleet ID and provide a <code>RuntimeConfiguration</code> object with an updated set of server process configurations.</p> <p>Each instance in a Amazon GameLift fleet checks regularly for an updated run-time configuration and changes how it launches server processes to comply with the latest version. Existing server processes are not affected by the update; run-time configuration changes are applied gradually as existing processes shut down and new processes are launched during Amazon GameLift's normal process recycling activity.</p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html"> Working with Fleets</a>.</p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateFleet</a> </p> </li> <li> <p> <a>ListFleets</a> </p> </li> <li> <p> <a>DeleteFleet</a> </p> </li> <li> <p>Describe fleets:</p> <ul> <li> <p> <a>DescribeFleetAttributes</a> </p> </li> <li> <p> <a>DescribeFleetCapacity</a> </p> </li> <li> <p> <a>DescribeFleetPortSettings</a> </p> </li> <li> <p> <a>DescribeFleetUtilization</a> </p> </li> <li> <p> <a>DescribeRuntimeConfiguration</a> </p> </li> <li> <p> <a>DescribeEC2InstanceLimits</a> </p> </li> <li> <p> <a>DescribeFleetEvents</a> </p> </li> </ul> </li> <li> <p>Update fleets:</p> <ul> <li> <p> <a>UpdateFleetAttributes</a> </p> </li> <li> <p> <a>UpdateFleetCapacity</a> </p> </li> <li> <p> <a>UpdateFleetPortSettings</a> </p> </li> <li> <p> <a>UpdateRuntimeConfiguration</a> </p> </li> </ul> </li> <li> <p>Manage fleet actions:</p> <ul> <li> <p> <a>StartFleetActions</a> </p> </li> <li> <p> <a>StopFleetActions</a> </p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_595092 = newJObject()
  if body != nil:
    body_595092 = body
  result = call_595091.call(nil, nil, nil, nil, body_595092)

var updateRuntimeConfiguration* = Call_UpdateRuntimeConfiguration_595078(
    name: "updateRuntimeConfiguration", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateRuntimeConfiguration",
    validator: validate_UpdateRuntimeConfiguration_595079, base: "/",
    url: url_UpdateRuntimeConfiguration_595080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateScript_595093 = ref object of OpenApiRestCall_593437
proc url_UpdateScript_595095(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateScript_595094(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates Realtime script metadata and content.</p> <p>To update script metadata, specify the script ID and provide updated name and/or version values. </p> <p>To update script content, provide an updated zip file by pointing to either a local file or an Amazon S3 bucket location. You can use either method regardless of how the original script was uploaded. Use the <i>Version</i> parameter to track updates to the script.</p> <p>If the call is successful, the updated metadata is stored in the script record and a revised script is uploaded to the Amazon GameLift service. Once the script is updated and acquired by a fleet instance, the new version is used for all new game sessions. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
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
  var valid_595096 = header.getOrDefault("X-Amz-Date")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Date", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-Security-Token")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-Security-Token", valid_595097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595098 = header.getOrDefault("X-Amz-Target")
  valid_595098 = validateParameter(valid_595098, JString, required = true,
                                 default = newJString("GameLift.UpdateScript"))
  if valid_595098 != nil:
    section.add "X-Amz-Target", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-Content-Sha256", valid_595099
  var valid_595100 = header.getOrDefault("X-Amz-Algorithm")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Algorithm", valid_595100
  var valid_595101 = header.getOrDefault("X-Amz-Signature")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-Signature", valid_595101
  var valid_595102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "X-Amz-SignedHeaders", valid_595102
  var valid_595103 = header.getOrDefault("X-Amz-Credential")
  valid_595103 = validateParameter(valid_595103, JString, required = false,
                                 default = nil)
  if valid_595103 != nil:
    section.add "X-Amz-Credential", valid_595103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595105: Call_UpdateScript_595093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates Realtime script metadata and content.</p> <p>To update script metadata, specify the script ID and provide updated name and/or version values. </p> <p>To update script content, provide an updated zip file by pointing to either a local file or an Amazon S3 bucket location. You can use either method regardless of how the original script was uploaded. Use the <i>Version</i> parameter to track updates to the script.</p> <p>If the call is successful, the updated metadata is stored in the script record and a revised script is uploaded to the Amazon GameLift service. Once the script is updated and acquired by a fleet instance, the new version is used for all new game sessions. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ## 
  let valid = call_595105.validator(path, query, header, formData, body)
  let scheme = call_595105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595105.url(scheme.get, call_595105.host, call_595105.base,
                         call_595105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595105, url, valid)

proc call*(call_595106: Call_UpdateScript_595093; body: JsonNode): Recallable =
  ## updateScript
  ## <p>Updates Realtime script metadata and content.</p> <p>To update script metadata, specify the script ID and provide updated name and/or version values. </p> <p>To update script content, provide an updated zip file by pointing to either a local file or an Amazon S3 bucket location. You can use either method regardless of how the original script was uploaded. Use the <i>Version</i> parameter to track updates to the script.</p> <p>If the call is successful, the updated metadata is stored in the script record and a revised script is uploaded to the Amazon GameLift service. Once the script is updated and acquired by a fleet instance, the new version is used for all new game sessions. </p> <p> <b>Learn more</b> </p> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html">Amazon GameLift Realtime Servers</a> </p> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateScript</a> </p> </li> <li> <p> <a>ListScripts</a> </p> </li> <li> <p> <a>DescribeScript</a> </p> </li> <li> <p> <a>UpdateScript</a> </p> </li> <li> <p> <a>DeleteScript</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_595107 = newJObject()
  if body != nil:
    body_595107 = body
  result = call_595106.call(nil, nil, nil, nil, body_595107)

var updateScript* = Call_UpdateScript_595093(name: "updateScript",
    meth: HttpMethod.HttpPost, host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.UpdateScript",
    validator: validate_UpdateScript_595094, base: "/", url: url_UpdateScript_595095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ValidateMatchmakingRuleSet_595108 = ref object of OpenApiRestCall_593437
proc url_ValidateMatchmakingRuleSet_595110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ValidateMatchmakingRuleSet_595109(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Validates the syntax of a matchmaking rule or rule set. This operation checks that the rule set is using syntactically correct JSON and that it conforms to allowed property expressions. To validate syntax, provide a rule set JSON string.</p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
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
  var valid_595111 = header.getOrDefault("X-Amz-Date")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Date", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-Security-Token")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-Security-Token", valid_595112
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595113 = header.getOrDefault("X-Amz-Target")
  valid_595113 = validateParameter(valid_595113, JString, required = true, default = newJString(
      "GameLift.ValidateMatchmakingRuleSet"))
  if valid_595113 != nil:
    section.add "X-Amz-Target", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-Content-Sha256", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Algorithm")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Algorithm", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-Signature")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-Signature", valid_595116
  var valid_595117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-SignedHeaders", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-Credential")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-Credential", valid_595118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595120: Call_ValidateMatchmakingRuleSet_595108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Validates the syntax of a matchmaking rule or rule set. This operation checks that the rule set is using syntactically correct JSON and that it conforms to allowed property expressions. To validate syntax, provide a rule set JSON string.</p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ## 
  let valid = call_595120.validator(path, query, header, formData, body)
  let scheme = call_595120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595120.url(scheme.get, call_595120.host, call_595120.base,
                         call_595120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595120, url, valid)

proc call*(call_595121: Call_ValidateMatchmakingRuleSet_595108; body: JsonNode): Recallable =
  ## validateMatchmakingRuleSet
  ## <p>Validates the syntax of a matchmaking rule or rule set. This operation checks that the rule set is using syntactically correct JSON and that it conforms to allowed property expressions. To validate syntax, provide a rule set JSON string.</p> <p> <b>Learn more</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/gamelift/latest/developerguide/match-rulesets.html">Build a Rule Set</a> </p> </li> </ul> <p> <b>Related operations</b> </p> <ul> <li> <p> <a>CreateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DescribeMatchmakingConfigurations</a> </p> </li> <li> <p> <a>UpdateMatchmakingConfiguration</a> </p> </li> <li> <p> <a>DeleteMatchmakingConfiguration</a> </p> </li> <li> <p> <a>CreateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DescribeMatchmakingRuleSets</a> </p> </li> <li> <p> <a>ValidateMatchmakingRuleSet</a> </p> </li> <li> <p> <a>DeleteMatchmakingRuleSet</a> </p> </li> </ul>
  ##   body: JObject (required)
  var body_595122 = newJObject()
  if body != nil:
    body_595122 = body
  result = call_595121.call(nil, nil, nil, nil, body_595122)

var validateMatchmakingRuleSet* = Call_ValidateMatchmakingRuleSet_595108(
    name: "validateMatchmakingRuleSet", meth: HttpMethod.HttpPost,
    host: "gamelift.amazonaws.com",
    route: "/#X-Amz-Target=GameLift.ValidateMatchmakingRuleSet",
    validator: validate_ValidateMatchmakingRuleSet_595109, base: "/",
    url: url_ValidateMatchmakingRuleSet_595110,
    schemes: {Scheme.Https, Scheme.Http})
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
