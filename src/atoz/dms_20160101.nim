
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Database Migration Service
## version: 2016-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Database Migration Service</fullname> <p>AWS Database Migration Service (AWS DMS) can migrate your data to and from the most widely used commercial and open-source databases such as Oracle, PostgreSQL, Microsoft SQL Server, Amazon Redshift, MariaDB, Amazon Aurora, MySQL, and SAP Adaptive Server Enterprise (ASE). The service supports homogeneous migrations such as Oracle to Oracle, as well as heterogeneous migrations between different database platforms, such as Oracle to MySQL or SQL Server to PostgreSQL.</p> <p>For more information about AWS DMS, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html">What Is AWS Database Migration Service?</a> in the <i>AWS Database Migration User Guide.</i> </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dms/
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dms.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dms.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dms.us-west-2.amazonaws.com",
                           "eu-west-2": "dms.eu-west-2.amazonaws.com", "ap-northeast-3": "dms.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "dms.eu-central-1.amazonaws.com",
                           "us-east-2": "dms.us-east-2.amazonaws.com",
                           "us-east-1": "dms.us-east-1.amazonaws.com", "cn-northwest-1": "dms.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "dms.ap-south-1.amazonaws.com",
                           "eu-north-1": "dms.eu-north-1.amazonaws.com", "ap-northeast-2": "dms.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dms.us-west-1.amazonaws.com",
                           "us-gov-east-1": "dms.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dms.eu-west-3.amazonaws.com",
                           "cn-north-1": "dms.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dms.sa-east-1.amazonaws.com",
                           "eu-west-1": "dms.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "dms.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dms.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "dms.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dms.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dms.ap-southeast-1.amazonaws.com",
      "us-west-2": "dms.us-west-2.amazonaws.com",
      "eu-west-2": "dms.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dms.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dms.eu-central-1.amazonaws.com",
      "us-east-2": "dms.us-east-2.amazonaws.com",
      "us-east-1": "dms.us-east-1.amazonaws.com",
      "cn-northwest-1": "dms.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dms.ap-south-1.amazonaws.com",
      "eu-north-1": "dms.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dms.ap-northeast-2.amazonaws.com",
      "us-west-1": "dms.us-west-1.amazonaws.com",
      "us-gov-east-1": "dms.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dms.eu-west-3.amazonaws.com",
      "cn-north-1": "dms.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dms.sa-east-1.amazonaws.com",
      "eu-west-1": "dms.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dms.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dms.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dms.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dms"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_612996 = ref object of OpenApiRestCall_612658
proc url_AddTagsToResource_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AddTagsToResource_612997(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "AmazonDMSv20160101.AddTagsToResource"))
  if valid_613123 != nil:
    section.add "X-Amz-Target", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Signature")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Signature", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Content-Sha256", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Date")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Date", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Credential")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Credential", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Security-Token")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Security-Token", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Algorithm")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Algorithm", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-SignedHeaders", valid_613130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_AddTagsToResource_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AddTagsToResource_612996; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var addTagsToResource* = Call_AddTagsToResource_612996(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource",
    validator: validate_AddTagsToResource_612997, base: "/",
    url: url_AddTagsToResource_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplyPendingMaintenanceAction_613265 = ref object of OpenApiRestCall_612658
proc url_ApplyPendingMaintenanceAction_613267(protocol: Scheme; host: string;
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

proc validate_ApplyPendingMaintenanceAction_613266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ApplyPendingMaintenanceAction"))
  if valid_613268 != nil:
    section.add "X-Amz-Target", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Signature")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Signature", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Content-Sha256", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Date")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Date", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Credential")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Credential", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Security-Token")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Security-Token", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Algorithm")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Algorithm", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-SignedHeaders", valid_613275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613277: Call_ApplyPendingMaintenanceAction_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_ApplyPendingMaintenanceAction_613265; body: JsonNode): Recallable =
  ## applyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var applyPendingMaintenanceAction* = Call_ApplyPendingMaintenanceAction_613265(
    name: "applyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction",
    validator: validate_ApplyPendingMaintenanceAction_613266, base: "/",
    url: url_ApplyPendingMaintenanceAction_613267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_613280 = ref object of OpenApiRestCall_612658
proc url_CreateEndpoint_613282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEndpoint_613281(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates an endpoint using the provided settings.
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEndpoint"))
  if valid_613283 != nil:
    section.add "X-Amz-Target", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Signature")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Signature", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Content-Sha256", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Date")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Date", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Credential")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Credential", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Security-Token")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Security-Token", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Algorithm")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Algorithm", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-SignedHeaders", valid_613290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613292: Call_CreateEndpoint_613280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint using the provided settings.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateEndpoint_613280; body: JsonNode): Recallable =
  ## createEndpoint
  ## Creates an endpoint using the provided settings.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createEndpoint* = Call_CreateEndpoint_613280(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint",
    validator: validate_CreateEndpoint_613281, base: "/", url: url_CreateEndpoint_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSubscription_613295 = ref object of OpenApiRestCall_612658
proc url_CreateEventSubscription_613297(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEventSubscription_613296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEventSubscription"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateEventSubscription_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateEventSubscription_613295; body: JsonNode): Recallable =
  ## createEventSubscription
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createEventSubscription* = Call_CreateEventSubscription_613295(
    name: "createEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription",
    validator: validate_CreateEventSubscription_613296, base: "/",
    url: url_CreateEventSubscription_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationInstance_613310 = ref object of OpenApiRestCall_612658
proc url_CreateReplicationInstance_613312(protocol: Scheme; host: string;
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

proc validate_CreateReplicationInstance_613311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates the replication instance using the specified parameters.</p> <p>AWS DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.APIRole.html">Creating the IAM Roles to Use With the AWS CLI and AWS DMS API</a>. For information on the required permissions, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.IAMPermissions.html">IAM Permissions Needed to Use AWS DMS</a>.</p>
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationInstance"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_CreateReplicationInstance_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates the replication instance using the specified parameters.</p> <p>AWS DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.APIRole.html">Creating the IAM Roles to Use With the AWS CLI and AWS DMS API</a>. For information on the required permissions, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.IAMPermissions.html">IAM Permissions Needed to Use AWS DMS</a>.</p>
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_CreateReplicationInstance_613310; body: JsonNode): Recallable =
  ## createReplicationInstance
  ## <p>Creates the replication instance using the specified parameters.</p> <p>AWS DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.APIRole.html">Creating the IAM Roles to Use With the AWS CLI and AWS DMS API</a>. For information on the required permissions, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.IAMPermissions.html">IAM Permissions Needed to Use AWS DMS</a>.</p>
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var createReplicationInstance* = Call_CreateReplicationInstance_613310(
    name: "createReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance",
    validator: validate_CreateReplicationInstance_613311, base: "/",
    url: url_CreateReplicationInstance_613312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationSubnetGroup_613325 = ref object of OpenApiRestCall_612658
proc url_CreateReplicationSubnetGroup_613327(protocol: Scheme; host: string;
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

proc validate_CreateReplicationSubnetGroup_613326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationSubnetGroup"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_CreateReplicationSubnetGroup_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CreateReplicationSubnetGroup_613325; body: JsonNode): Recallable =
  ## createReplicationSubnetGroup
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var createReplicationSubnetGroup* = Call_CreateReplicationSubnetGroup_613325(
    name: "createReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup",
    validator: validate_CreateReplicationSubnetGroup_613326, base: "/",
    url: url_CreateReplicationSubnetGroup_613327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationTask_613340 = ref object of OpenApiRestCall_612658
proc url_CreateReplicationTask_613342(protocol: Scheme; host: string; base: string;
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

proc validate_CreateReplicationTask_613341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a replication task using the specified parameters.
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationTask"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_CreateReplicationTask_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication task using the specified parameters.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_CreateReplicationTask_613340; body: JsonNode): Recallable =
  ## createReplicationTask
  ## Creates a replication task using the specified parameters.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var createReplicationTask* = Call_CreateReplicationTask_613340(
    name: "createReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask",
    validator: validate_CreateReplicationTask_613341, base: "/",
    url: url_CreateReplicationTask_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificate_613355 = ref object of OpenApiRestCall_612658
proc url_DeleteCertificate_613357(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCertificate_613356(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the specified certificate. 
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteCertificate"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_DeleteCertificate_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified certificate. 
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_DeleteCertificate_613355; body: JsonNode): Recallable =
  ## deleteCertificate
  ## Deletes the specified certificate. 
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var deleteCertificate* = Call_DeleteCertificate_613355(name: "deleteCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate",
    validator: validate_DeleteCertificate_613356, base: "/",
    url: url_DeleteCertificate_613357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_613370 = ref object of OpenApiRestCall_612658
proc url_DeleteConnection_613372(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConnection_613371(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes the connection between a replication instance and an endpoint.
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteConnection"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_DeleteConnection_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the connection between a replication instance and an endpoint.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_DeleteConnection_613370; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes the connection between a replication instance and an endpoint.
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var deleteConnection* = Call_DeleteConnection_613370(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteConnection",
    validator: validate_DeleteConnection_613371, base: "/",
    url: url_DeleteConnection_613372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_613385 = ref object of OpenApiRestCall_612658
proc url_DeleteEndpoint_613387(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_613386(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEndpoint"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_DeleteEndpoint_613385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_DeleteEndpoint_613385; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var deleteEndpoint* = Call_DeleteEndpoint_613385(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint",
    validator: validate_DeleteEndpoint_613386, base: "/", url: url_DeleteEndpoint_613387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSubscription_613400 = ref object of OpenApiRestCall_612658
proc url_DeleteEventSubscription_613402(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEventSubscription_613401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Deletes an AWS DMS event subscription. 
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEventSubscription"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_DeleteEventSubscription_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an AWS DMS event subscription. 
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_DeleteEventSubscription_613400; body: JsonNode): Recallable =
  ## deleteEventSubscription
  ##  Deletes an AWS DMS event subscription. 
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var deleteEventSubscription* = Call_DeleteEventSubscription_613400(
    name: "deleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription",
    validator: validate_DeleteEventSubscription_613401, base: "/",
    url: url_DeleteEventSubscription_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationInstance_613415 = ref object of OpenApiRestCall_612658
proc url_DeleteReplicationInstance_613417(protocol: Scheme; host: string;
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

proc validate_DeleteReplicationInstance_613416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationInstance"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_DeleteReplicationInstance_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_DeleteReplicationInstance_613415; body: JsonNode): Recallable =
  ## deleteReplicationInstance
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var deleteReplicationInstance* = Call_DeleteReplicationInstance_613415(
    name: "deleteReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance",
    validator: validate_DeleteReplicationInstance_613416, base: "/",
    url: url_DeleteReplicationInstance_613417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationSubnetGroup_613430 = ref object of OpenApiRestCall_612658
proc url_DeleteReplicationSubnetGroup_613432(protocol: Scheme; host: string;
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

proc validate_DeleteReplicationSubnetGroup_613431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a subnet group.
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
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationSubnetGroup"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_DeleteReplicationSubnetGroup_613430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subnet group.
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_DeleteReplicationSubnetGroup_613430; body: JsonNode): Recallable =
  ## deleteReplicationSubnetGroup
  ## Deletes a subnet group.
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var deleteReplicationSubnetGroup* = Call_DeleteReplicationSubnetGroup_613430(
    name: "deleteReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup",
    validator: validate_DeleteReplicationSubnetGroup_613431, base: "/",
    url: url_DeleteReplicationSubnetGroup_613432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationTask_613445 = ref object of OpenApiRestCall_612658
proc url_DeleteReplicationTask_613447(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReplicationTask_613446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified replication task.
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
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationTask"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_DeleteReplicationTask_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified replication task.
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_DeleteReplicationTask_613445; body: JsonNode): Recallable =
  ## deleteReplicationTask
  ## Deletes the specified replication task.
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var deleteReplicationTask* = Call_DeleteReplicationTask_613445(
    name: "deleteReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask",
    validator: validate_DeleteReplicationTask_613446, base: "/",
    url: url_DeleteReplicationTask_613447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_613460 = ref object of OpenApiRestCall_612658
proc url_DescribeAccountAttributes_613462(protocol: Scheme; host: string;
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

proc validate_DescribeAccountAttributes_613461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeAccountAttributes"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_DescribeAccountAttributes_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_DescribeAccountAttributes_613460; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var describeAccountAttributes* = Call_DescribeAccountAttributes_613460(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_613461, base: "/",
    url: url_DescribeAccountAttributes_613462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificates_613475 = ref object of OpenApiRestCall_612658
proc url_DescribeCertificates_613477(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCertificates_613476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides a description of the certificate.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613478 = query.getOrDefault("Marker")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "Marker", valid_613478
  var valid_613479 = query.getOrDefault("MaxRecords")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "MaxRecords", valid_613479
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
  var valid_613480 = header.getOrDefault("X-Amz-Target")
  valid_613480 = validateParameter(valid_613480, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeCertificates"))
  if valid_613480 != nil:
    section.add "X-Amz-Target", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Signature")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Signature", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Content-Sha256", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Date")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Date", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Credential")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Credential", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Security-Token")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Security-Token", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Algorithm")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Algorithm", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-SignedHeaders", valid_613487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613489: Call_DescribeCertificates_613475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a description of the certificate.
  ## 
  let valid = call_613489.validator(path, query, header, formData, body)
  let scheme = call_613489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613489.url(scheme.get, call_613489.host, call_613489.base,
                         call_613489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613489, url, valid)

proc call*(call_613490: Call_DescribeCertificates_613475; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeCertificates
  ## Provides a description of the certificate.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613491 = newJObject()
  var body_613492 = newJObject()
  add(query_613491, "Marker", newJString(Marker))
  if body != nil:
    body_613492 = body
  add(query_613491, "MaxRecords", newJString(MaxRecords))
  result = call_613490.call(nil, query_613491, nil, nil, body_613492)

var describeCertificates* = Call_DescribeCertificates_613475(
    name: "describeCertificates", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates",
    validator: validate_DescribeCertificates_613476, base: "/",
    url: url_DescribeCertificates_613477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_613494 = ref object of OpenApiRestCall_612658
proc url_DescribeConnections_613496(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeConnections_613495(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613497 = query.getOrDefault("Marker")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "Marker", valid_613497
  var valid_613498 = query.getOrDefault("MaxRecords")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "MaxRecords", valid_613498
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
  var valid_613499 = header.getOrDefault("X-Amz-Target")
  valid_613499 = validateParameter(valid_613499, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeConnections"))
  if valid_613499 != nil:
    section.add "X-Amz-Target", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Signature")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Signature", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Content-Sha256", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Date")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Date", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Credential")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Credential", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Security-Token")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Security-Token", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Algorithm")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Algorithm", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-SignedHeaders", valid_613506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613508: Call_DescribeConnections_613494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ## 
  let valid = call_613508.validator(path, query, header, formData, body)
  let scheme = call_613508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613508.url(scheme.get, call_613508.host, call_613508.base,
                         call_613508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613508, url, valid)

proc call*(call_613509: Call_DescribeConnections_613494; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeConnections
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613510 = newJObject()
  var body_613511 = newJObject()
  add(query_613510, "Marker", newJString(Marker))
  if body != nil:
    body_613511 = body
  add(query_613510, "MaxRecords", newJString(MaxRecords))
  result = call_613509.call(nil, query_613510, nil, nil, body_613511)

var describeConnections* = Call_DescribeConnections_613494(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeConnections",
    validator: validate_DescribeConnections_613495, base: "/",
    url: url_DescribeConnections_613496, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointTypes_613512 = ref object of OpenApiRestCall_612658
proc url_DescribeEndpointTypes_613514(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEndpointTypes_613513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the type of endpoints available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613515 = query.getOrDefault("Marker")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "Marker", valid_613515
  var valid_613516 = query.getOrDefault("MaxRecords")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "MaxRecords", valid_613516
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
  var valid_613517 = header.getOrDefault("X-Amz-Target")
  valid_613517 = validateParameter(valid_613517, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpointTypes"))
  if valid_613517 != nil:
    section.add "X-Amz-Target", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Signature")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Signature", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Content-Sha256", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Date")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Date", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Credential")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Credential", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Security-Token")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Security-Token", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Algorithm")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Algorithm", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-SignedHeaders", valid_613524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613526: Call_DescribeEndpointTypes_613512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the type of endpoints available.
  ## 
  let valid = call_613526.validator(path, query, header, formData, body)
  let scheme = call_613526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613526.url(scheme.get, call_613526.host, call_613526.base,
                         call_613526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613526, url, valid)

proc call*(call_613527: Call_DescribeEndpointTypes_613512; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeEndpointTypes
  ## Returns information about the type of endpoints available.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613528 = newJObject()
  var body_613529 = newJObject()
  add(query_613528, "Marker", newJString(Marker))
  if body != nil:
    body_613529 = body
  add(query_613528, "MaxRecords", newJString(MaxRecords))
  result = call_613527.call(nil, query_613528, nil, nil, body_613529)

var describeEndpointTypes* = Call_DescribeEndpointTypes_613512(
    name: "describeEndpointTypes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes",
    validator: validate_DescribeEndpointTypes_613513, base: "/",
    url: url_DescribeEndpointTypes_613514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_613530 = ref object of OpenApiRestCall_612658
proc url_DescribeEndpoints_613532(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEndpoints_613531(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about the endpoints for your account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613533 = query.getOrDefault("Marker")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "Marker", valid_613533
  var valid_613534 = query.getOrDefault("MaxRecords")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "MaxRecords", valid_613534
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
  var valid_613535 = header.getOrDefault("X-Amz-Target")
  valid_613535 = validateParameter(valid_613535, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpoints"))
  if valid_613535 != nil:
    section.add "X-Amz-Target", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Signature")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Signature", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Content-Sha256", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Date")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Date", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Credential")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Credential", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Security-Token")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Security-Token", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Algorithm")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Algorithm", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-SignedHeaders", valid_613542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613544: Call_DescribeEndpoints_613530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the endpoints for your account in the current region.
  ## 
  let valid = call_613544.validator(path, query, header, formData, body)
  let scheme = call_613544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613544.url(scheme.get, call_613544.host, call_613544.base,
                         call_613544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613544, url, valid)

proc call*(call_613545: Call_DescribeEndpoints_613530; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeEndpoints
  ## Returns information about the endpoints for your account in the current region.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613546 = newJObject()
  var body_613547 = newJObject()
  add(query_613546, "Marker", newJString(Marker))
  if body != nil:
    body_613547 = body
  add(query_613546, "MaxRecords", newJString(MaxRecords))
  result = call_613545.call(nil, query_613546, nil, nil, body_613547)

var describeEndpoints* = Call_DescribeEndpoints_613530(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints",
    validator: validate_DescribeEndpoints_613531, base: "/",
    url: url_DescribeEndpoints_613532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventCategories_613548 = ref object of OpenApiRestCall_612658
proc url_DescribeEventCategories_613550(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventCategories_613549(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
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
  var valid_613551 = header.getOrDefault("X-Amz-Target")
  valid_613551 = validateParameter(valid_613551, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventCategories"))
  if valid_613551 != nil:
    section.add "X-Amz-Target", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Security-Token")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Security-Token", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Algorithm")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Algorithm", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-SignedHeaders", valid_613558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_DescribeEventCategories_613548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_DescribeEventCategories_613548; body: JsonNode): Recallable =
  ## describeEventCategories
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ##   body: JObject (required)
  var body_613562 = newJObject()
  if body != nil:
    body_613562 = body
  result = call_613561.call(nil, nil, nil, nil, body_613562)

var describeEventCategories* = Call_DescribeEventCategories_613548(
    name: "describeEventCategories", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories",
    validator: validate_DescribeEventCategories_613549, base: "/",
    url: url_DescribeEventCategories_613550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventSubscriptions_613563 = ref object of OpenApiRestCall_612658
proc url_DescribeEventSubscriptions_613565(protocol: Scheme; host: string;
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

proc validate_DescribeEventSubscriptions_613564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613566 = query.getOrDefault("Marker")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "Marker", valid_613566
  var valid_613567 = query.getOrDefault("MaxRecords")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "MaxRecords", valid_613567
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
  var valid_613568 = header.getOrDefault("X-Amz-Target")
  valid_613568 = validateParameter(valid_613568, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventSubscriptions"))
  if valid_613568 != nil:
    section.add "X-Amz-Target", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_DescribeEventSubscriptions_613563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_DescribeEventSubscriptions_613563; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeEventSubscriptions
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613579 = newJObject()
  var body_613580 = newJObject()
  add(query_613579, "Marker", newJString(Marker))
  if body != nil:
    body_613580 = body
  add(query_613579, "MaxRecords", newJString(MaxRecords))
  result = call_613578.call(nil, query_613579, nil, nil, body_613580)

var describeEventSubscriptions* = Call_DescribeEventSubscriptions_613563(
    name: "describeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions",
    validator: validate_DescribeEventSubscriptions_613564, base: "/",
    url: url_DescribeEventSubscriptions_613565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_613581 = ref object of OpenApiRestCall_612658
proc url_DescribeEvents_613583(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEvents_613582(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613584 = query.getOrDefault("Marker")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "Marker", valid_613584
  var valid_613585 = query.getOrDefault("MaxRecords")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "MaxRecords", valid_613585
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
  var valid_613586 = header.getOrDefault("X-Amz-Target")
  valid_613586 = validateParameter(valid_613586, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEvents"))
  if valid_613586 != nil:
    section.add "X-Amz-Target", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Signature")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Signature", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Content-Sha256", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Date")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Date", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Credential")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Credential", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Security-Token")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Security-Token", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Algorithm")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Algorithm", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-SignedHeaders", valid_613593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613595: Call_DescribeEvents_613581; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ## 
  let valid = call_613595.validator(path, query, header, formData, body)
  let scheme = call_613595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613595.url(scheme.get, call_613595.host, call_613595.base,
                         call_613595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613595, url, valid)

proc call*(call_613596: Call_DescribeEvents_613581; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeEvents
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613597 = newJObject()
  var body_613598 = newJObject()
  add(query_613597, "Marker", newJString(Marker))
  if body != nil:
    body_613598 = body
  add(query_613597, "MaxRecords", newJString(MaxRecords))
  result = call_613596.call(nil, query_613597, nil, nil, body_613598)

var describeEvents* = Call_DescribeEvents_613581(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEvents",
    validator: validate_DescribeEvents_613582, base: "/", url: url_DescribeEvents_613583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrderableReplicationInstances_613599 = ref object of OpenApiRestCall_612658
proc url_DescribeOrderableReplicationInstances_613601(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrderableReplicationInstances_613600(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the replication instance types that can be created in the specified region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613602 = query.getOrDefault("Marker")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "Marker", valid_613602
  var valid_613603 = query.getOrDefault("MaxRecords")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "MaxRecords", valid_613603
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
  var valid_613604 = header.getOrDefault("X-Amz-Target")
  valid_613604 = validateParameter(valid_613604, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeOrderableReplicationInstances"))
  if valid_613604 != nil:
    section.add "X-Amz-Target", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Signature")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Signature", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Content-Sha256", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Date")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Date", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Credential")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Credential", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Security-Token")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Security-Token", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Algorithm")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Algorithm", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-SignedHeaders", valid_613611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613613: Call_DescribeOrderableReplicationInstances_613599;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication instance types that can be created in the specified region.
  ## 
  let valid = call_613613.validator(path, query, header, formData, body)
  let scheme = call_613613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613613.url(scheme.get, call_613613.host, call_613613.base,
                         call_613613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613613, url, valid)

proc call*(call_613614: Call_DescribeOrderableReplicationInstances_613599;
          body: JsonNode; Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeOrderableReplicationInstances
  ## Returns information about the replication instance types that can be created in the specified region.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613615 = newJObject()
  var body_613616 = newJObject()
  add(query_613615, "Marker", newJString(Marker))
  if body != nil:
    body_613616 = body
  add(query_613615, "MaxRecords", newJString(MaxRecords))
  result = call_613614.call(nil, query_613615, nil, nil, body_613616)

var describeOrderableReplicationInstances* = Call_DescribeOrderableReplicationInstances_613599(
    name: "describeOrderableReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances",
    validator: validate_DescribeOrderableReplicationInstances_613600, base: "/",
    url: url_DescribeOrderableReplicationInstances_613601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingMaintenanceActions_613617 = ref object of OpenApiRestCall_612658
proc url_DescribePendingMaintenanceActions_613619(protocol: Scheme; host: string;
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

proc validate_DescribePendingMaintenanceActions_613618(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## For internal use only
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613620 = query.getOrDefault("Marker")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "Marker", valid_613620
  var valid_613621 = query.getOrDefault("MaxRecords")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "MaxRecords", valid_613621
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
  var valid_613622 = header.getOrDefault("X-Amz-Target")
  valid_613622 = validateParameter(valid_613622, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribePendingMaintenanceActions"))
  if valid_613622 != nil:
    section.add "X-Amz-Target", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Signature")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Signature", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Content-Sha256", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Date")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Date", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Credential")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Credential", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Security-Token")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Security-Token", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Algorithm")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Algorithm", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-SignedHeaders", valid_613629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613631: Call_DescribePendingMaintenanceActions_613617;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For internal use only
  ## 
  let valid = call_613631.validator(path, query, header, formData, body)
  let scheme = call_613631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613631.url(scheme.get, call_613631.host, call_613631.base,
                         call_613631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613631, url, valid)

proc call*(call_613632: Call_DescribePendingMaintenanceActions_613617;
          body: JsonNode; Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describePendingMaintenanceActions
  ## For internal use only
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613633 = newJObject()
  var body_613634 = newJObject()
  add(query_613633, "Marker", newJString(Marker))
  if body != nil:
    body_613634 = body
  add(query_613633, "MaxRecords", newJString(MaxRecords))
  result = call_613632.call(nil, query_613633, nil, nil, body_613634)

var describePendingMaintenanceActions* = Call_DescribePendingMaintenanceActions_613617(
    name: "describePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions",
    validator: validate_DescribePendingMaintenanceActions_613618, base: "/",
    url: url_DescribePendingMaintenanceActions_613619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRefreshSchemasStatus_613635 = ref object of OpenApiRestCall_612658
proc url_DescribeRefreshSchemasStatus_613637(protocol: Scheme; host: string;
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

proc validate_DescribeRefreshSchemasStatus_613636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the status of the RefreshSchemas operation.
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
  var valid_613638 = header.getOrDefault("X-Amz-Target")
  valid_613638 = validateParameter(valid_613638, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeRefreshSchemasStatus"))
  if valid_613638 != nil:
    section.add "X-Amz-Target", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Signature")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Signature", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Content-Sha256", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Date")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Date", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Credential")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Credential", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Security-Token")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Security-Token", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Algorithm")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Algorithm", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-SignedHeaders", valid_613645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613647: Call_DescribeRefreshSchemasStatus_613635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of the RefreshSchemas operation.
  ## 
  let valid = call_613647.validator(path, query, header, formData, body)
  let scheme = call_613647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613647.url(scheme.get, call_613647.host, call_613647.base,
                         call_613647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613647, url, valid)

proc call*(call_613648: Call_DescribeRefreshSchemasStatus_613635; body: JsonNode): Recallable =
  ## describeRefreshSchemasStatus
  ## Returns the status of the RefreshSchemas operation.
  ##   body: JObject (required)
  var body_613649 = newJObject()
  if body != nil:
    body_613649 = body
  result = call_613648.call(nil, nil, nil, nil, body_613649)

var describeRefreshSchemasStatus* = Call_DescribeRefreshSchemasStatus_613635(
    name: "describeRefreshSchemasStatus", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus",
    validator: validate_DescribeRefreshSchemasStatus_613636, base: "/",
    url: url_DescribeRefreshSchemasStatus_613637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstanceTaskLogs_613650 = ref object of OpenApiRestCall_612658
proc url_DescribeReplicationInstanceTaskLogs_613652(protocol: Scheme; host: string;
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

proc validate_DescribeReplicationInstanceTaskLogs_613651(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the task logs for the specified task.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613653 = query.getOrDefault("Marker")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "Marker", valid_613653
  var valid_613654 = query.getOrDefault("MaxRecords")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "MaxRecords", valid_613654
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
  var valid_613655 = header.getOrDefault("X-Amz-Target")
  valid_613655 = validateParameter(valid_613655, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"))
  if valid_613655 != nil:
    section.add "X-Amz-Target", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Signature")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Signature", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Content-Sha256", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Date")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Date", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Credential")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Credential", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Security-Token")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Security-Token", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Algorithm")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Algorithm", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-SignedHeaders", valid_613662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613664: Call_DescribeReplicationInstanceTaskLogs_613650;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the task logs for the specified task.
  ## 
  let valid = call_613664.validator(path, query, header, formData, body)
  let scheme = call_613664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613664.url(scheme.get, call_613664.host, call_613664.base,
                         call_613664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613664, url, valid)

proc call*(call_613665: Call_DescribeReplicationInstanceTaskLogs_613650;
          body: JsonNode; Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeReplicationInstanceTaskLogs
  ## Returns information about the task logs for the specified task.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613666 = newJObject()
  var body_613667 = newJObject()
  add(query_613666, "Marker", newJString(Marker))
  if body != nil:
    body_613667 = body
  add(query_613666, "MaxRecords", newJString(MaxRecords))
  result = call_613665.call(nil, query_613666, nil, nil, body_613667)

var describeReplicationInstanceTaskLogs* = Call_DescribeReplicationInstanceTaskLogs_613650(
    name: "describeReplicationInstanceTaskLogs", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs",
    validator: validate_DescribeReplicationInstanceTaskLogs_613651, base: "/",
    url: url_DescribeReplicationInstanceTaskLogs_613652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstances_613668 = ref object of OpenApiRestCall_612658
proc url_DescribeReplicationInstances_613670(protocol: Scheme; host: string;
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

proc validate_DescribeReplicationInstances_613669(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about replication instances for your account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613671 = query.getOrDefault("Marker")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "Marker", valid_613671
  var valid_613672 = query.getOrDefault("MaxRecords")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "MaxRecords", valid_613672
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
  var valid_613673 = header.getOrDefault("X-Amz-Target")
  valid_613673 = validateParameter(valid_613673, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstances"))
  if valid_613673 != nil:
    section.add "X-Amz-Target", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Signature")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Signature", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Content-Sha256", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Date")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Date", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Credential")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Credential", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Security-Token")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Security-Token", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Algorithm")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Algorithm", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-SignedHeaders", valid_613680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613682: Call_DescribeReplicationInstances_613668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication instances for your account in the current region.
  ## 
  let valid = call_613682.validator(path, query, header, formData, body)
  let scheme = call_613682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613682.url(scheme.get, call_613682.host, call_613682.base,
                         call_613682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613682, url, valid)

proc call*(call_613683: Call_DescribeReplicationInstances_613668; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeReplicationInstances
  ## Returns information about replication instances for your account in the current region.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613684 = newJObject()
  var body_613685 = newJObject()
  add(query_613684, "Marker", newJString(Marker))
  if body != nil:
    body_613685 = body
  add(query_613684, "MaxRecords", newJString(MaxRecords))
  result = call_613683.call(nil, query_613684, nil, nil, body_613685)

var describeReplicationInstances* = Call_DescribeReplicationInstances_613668(
    name: "describeReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances",
    validator: validate_DescribeReplicationInstances_613669, base: "/",
    url: url_DescribeReplicationInstances_613670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationSubnetGroups_613686 = ref object of OpenApiRestCall_612658
proc url_DescribeReplicationSubnetGroups_613688(protocol: Scheme; host: string;
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

proc validate_DescribeReplicationSubnetGroups_613687(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the replication subnet groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613689 = query.getOrDefault("Marker")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "Marker", valid_613689
  var valid_613690 = query.getOrDefault("MaxRecords")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "MaxRecords", valid_613690
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
  var valid_613691 = header.getOrDefault("X-Amz-Target")
  valid_613691 = validateParameter(valid_613691, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationSubnetGroups"))
  if valid_613691 != nil:
    section.add "X-Amz-Target", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Signature")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Signature", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Content-Sha256", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Date")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Date", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Credential")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Credential", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Security-Token")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Security-Token", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Algorithm")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Algorithm", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-SignedHeaders", valid_613698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613700: Call_DescribeReplicationSubnetGroups_613686;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication subnet groups.
  ## 
  let valid = call_613700.validator(path, query, header, formData, body)
  let scheme = call_613700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613700.url(scheme.get, call_613700.host, call_613700.base,
                         call_613700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613700, url, valid)

proc call*(call_613701: Call_DescribeReplicationSubnetGroups_613686;
          body: JsonNode; Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeReplicationSubnetGroups
  ## Returns information about the replication subnet groups.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613702 = newJObject()
  var body_613703 = newJObject()
  add(query_613702, "Marker", newJString(Marker))
  if body != nil:
    body_613703 = body
  add(query_613702, "MaxRecords", newJString(MaxRecords))
  result = call_613701.call(nil, query_613702, nil, nil, body_613703)

var describeReplicationSubnetGroups* = Call_DescribeReplicationSubnetGroups_613686(
    name: "describeReplicationSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups",
    validator: validate_DescribeReplicationSubnetGroups_613687, base: "/",
    url: url_DescribeReplicationSubnetGroups_613688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTaskAssessmentResults_613704 = ref object of OpenApiRestCall_612658
proc url_DescribeReplicationTaskAssessmentResults_613706(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReplicationTaskAssessmentResults_613705(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613707 = query.getOrDefault("Marker")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "Marker", valid_613707
  var valid_613708 = query.getOrDefault("MaxRecords")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "MaxRecords", valid_613708
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
  var valid_613709 = header.getOrDefault("X-Amz-Target")
  valid_613709 = validateParameter(valid_613709, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"))
  if valid_613709 != nil:
    section.add "X-Amz-Target", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Signature")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Signature", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Content-Sha256", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Date")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Date", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Credential")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Credential", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Security-Token")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Security-Token", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Algorithm")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Algorithm", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-SignedHeaders", valid_613716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613718: Call_DescribeReplicationTaskAssessmentResults_613704;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ## 
  let valid = call_613718.validator(path, query, header, formData, body)
  let scheme = call_613718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613718.url(scheme.get, call_613718.host, call_613718.base,
                         call_613718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613718, url, valid)

proc call*(call_613719: Call_DescribeReplicationTaskAssessmentResults_613704;
          body: JsonNode; Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeReplicationTaskAssessmentResults
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613720 = newJObject()
  var body_613721 = newJObject()
  add(query_613720, "Marker", newJString(Marker))
  if body != nil:
    body_613721 = body
  add(query_613720, "MaxRecords", newJString(MaxRecords))
  result = call_613719.call(nil, query_613720, nil, nil, body_613721)

var describeReplicationTaskAssessmentResults* = Call_DescribeReplicationTaskAssessmentResults_613704(
    name: "describeReplicationTaskAssessmentResults", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults",
    validator: validate_DescribeReplicationTaskAssessmentResults_613705,
    base: "/", url: url_DescribeReplicationTaskAssessmentResults_613706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTasks_613722 = ref object of OpenApiRestCall_612658
proc url_DescribeReplicationTasks_613724(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReplicationTasks_613723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about replication tasks for your account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613725 = query.getOrDefault("Marker")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "Marker", valid_613725
  var valid_613726 = query.getOrDefault("MaxRecords")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "MaxRecords", valid_613726
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
  var valid_613727 = header.getOrDefault("X-Amz-Target")
  valid_613727 = validateParameter(valid_613727, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTasks"))
  if valid_613727 != nil:
    section.add "X-Amz-Target", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Signature")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Signature", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Content-Sha256", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Date")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Date", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Credential")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Credential", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Security-Token")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Security-Token", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Algorithm")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Algorithm", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-SignedHeaders", valid_613734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613736: Call_DescribeReplicationTasks_613722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication tasks for your account in the current region.
  ## 
  let valid = call_613736.validator(path, query, header, formData, body)
  let scheme = call_613736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613736.url(scheme.get, call_613736.host, call_613736.base,
                         call_613736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613736, url, valid)

proc call*(call_613737: Call_DescribeReplicationTasks_613722; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeReplicationTasks
  ## Returns information about replication tasks for your account in the current region.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613738 = newJObject()
  var body_613739 = newJObject()
  add(query_613738, "Marker", newJString(Marker))
  if body != nil:
    body_613739 = body
  add(query_613738, "MaxRecords", newJString(MaxRecords))
  result = call_613737.call(nil, query_613738, nil, nil, body_613739)

var describeReplicationTasks* = Call_DescribeReplicationTasks_613722(
    name: "describeReplicationTasks", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks",
    validator: validate_DescribeReplicationTasks_613723, base: "/",
    url: url_DescribeReplicationTasks_613724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchemas_613740 = ref object of OpenApiRestCall_612658
proc url_DescribeSchemas_613742(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchemas_613741(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613743 = query.getOrDefault("Marker")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "Marker", valid_613743
  var valid_613744 = query.getOrDefault("MaxRecords")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "MaxRecords", valid_613744
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
  var valid_613745 = header.getOrDefault("X-Amz-Target")
  valid_613745 = validateParameter(valid_613745, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeSchemas"))
  if valid_613745 != nil:
    section.add "X-Amz-Target", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Signature")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Signature", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Content-Sha256", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Date")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Date", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Credential")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Credential", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Security-Token")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Security-Token", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Algorithm")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Algorithm", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-SignedHeaders", valid_613752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613754: Call_DescribeSchemas_613740; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ## 
  let valid = call_613754.validator(path, query, header, formData, body)
  let scheme = call_613754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613754.url(scheme.get, call_613754.host, call_613754.base,
                         call_613754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613754, url, valid)

proc call*(call_613755: Call_DescribeSchemas_613740; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeSchemas
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613756 = newJObject()
  var body_613757 = newJObject()
  add(query_613756, "Marker", newJString(Marker))
  if body != nil:
    body_613757 = body
  add(query_613756, "MaxRecords", newJString(MaxRecords))
  result = call_613755.call(nil, query_613756, nil, nil, body_613757)

var describeSchemas* = Call_DescribeSchemas_613740(name: "describeSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas",
    validator: validate_DescribeSchemas_613741, base: "/", url: url_DescribeSchemas_613742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTableStatistics_613758 = ref object of OpenApiRestCall_612658
proc url_DescribeTableStatistics_613760(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTableStatistics_613759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxRecords: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_613761 = query.getOrDefault("Marker")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "Marker", valid_613761
  var valid_613762 = query.getOrDefault("MaxRecords")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "MaxRecords", valid_613762
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
  var valid_613763 = header.getOrDefault("X-Amz-Target")
  valid_613763 = validateParameter(valid_613763, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeTableStatistics"))
  if valid_613763 != nil:
    section.add "X-Amz-Target", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Signature")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Signature", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Content-Sha256", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Date")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Date", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Credential")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Credential", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Security-Token")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Security-Token", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Algorithm")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Algorithm", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-SignedHeaders", valid_613770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613772: Call_DescribeTableStatistics_613758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ## 
  let valid = call_613772.validator(path, query, header, formData, body)
  let scheme = call_613772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613772.url(scheme.get, call_613772.host, call_613772.base,
                         call_613772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613772, url, valid)

proc call*(call_613773: Call_DescribeTableStatistics_613758; body: JsonNode;
          Marker: string = ""; MaxRecords: string = ""): Recallable =
  ## describeTableStatistics
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  ##   MaxRecords: string
  ##             : Pagination limit
  var query_613774 = newJObject()
  var body_613775 = newJObject()
  add(query_613774, "Marker", newJString(Marker))
  if body != nil:
    body_613775 = body
  add(query_613774, "MaxRecords", newJString(MaxRecords))
  result = call_613773.call(nil, query_613774, nil, nil, body_613775)

var describeTableStatistics* = Call_DescribeTableStatistics_613758(
    name: "describeTableStatistics", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics",
    validator: validate_DescribeTableStatistics_613759, base: "/",
    url: url_DescribeTableStatistics_613760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificate_613776 = ref object of OpenApiRestCall_612658
proc url_ImportCertificate_613778(protocol: Scheme; host: string; base: string;
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

proc validate_ImportCertificate_613777(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Uploads the specified certificate.
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
  var valid_613779 = header.getOrDefault("X-Amz-Target")
  valid_613779 = validateParameter(valid_613779, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ImportCertificate"))
  if valid_613779 != nil:
    section.add "X-Amz-Target", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Signature")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Signature", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Content-Sha256", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Date")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Date", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Credential")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Credential", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Security-Token")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Security-Token", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Algorithm")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Algorithm", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-SignedHeaders", valid_613786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613788: Call_ImportCertificate_613776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads the specified certificate.
  ## 
  let valid = call_613788.validator(path, query, header, formData, body)
  let scheme = call_613788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613788.url(scheme.get, call_613788.host, call_613788.base,
                         call_613788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613788, url, valid)

proc call*(call_613789: Call_ImportCertificate_613776; body: JsonNode): Recallable =
  ## importCertificate
  ## Uploads the specified certificate.
  ##   body: JObject (required)
  var body_613790 = newJObject()
  if body != nil:
    body_613790 = body
  result = call_613789.call(nil, nil, nil, nil, body_613790)

var importCertificate* = Call_ImportCertificate_613776(name: "importCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ImportCertificate",
    validator: validate_ImportCertificate_613777, base: "/",
    url: url_ImportCertificate_613778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613791 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613793(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613792(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags for an AWS DMS resource.
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
  var valid_613794 = header.getOrDefault("X-Amz-Target")
  valid_613794 = validateParameter(valid_613794, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ListTagsForResource"))
  if valid_613794 != nil:
    section.add "X-Amz-Target", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Signature")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Signature", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Content-Sha256", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Date")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Date", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Credential")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Credential", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Security-Token")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Security-Token", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Algorithm")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Algorithm", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-SignedHeaders", valid_613801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613803: Call_ListTagsForResource_613791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for an AWS DMS resource.
  ## 
  let valid = call_613803.validator(path, query, header, formData, body)
  let scheme = call_613803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613803.url(scheme.get, call_613803.host, call_613803.base,
                         call_613803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613803, url, valid)

proc call*(call_613804: Call_ListTagsForResource_613791; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags for an AWS DMS resource.
  ##   body: JObject (required)
  var body_613805 = newJObject()
  if body != nil:
    body_613805 = body
  result = call_613804.call(nil, nil, nil, nil, body_613805)

var listTagsForResource* = Call_ListTagsForResource_613791(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource",
    validator: validate_ListTagsForResource_613792, base: "/",
    url: url_ListTagsForResource_613793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEndpoint_613806 = ref object of OpenApiRestCall_612658
proc url_ModifyEndpoint_613808(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyEndpoint_613807(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Modifies the specified endpoint.
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
  var valid_613809 = header.getOrDefault("X-Amz-Target")
  valid_613809 = validateParameter(valid_613809, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEndpoint"))
  if valid_613809 != nil:
    section.add "X-Amz-Target", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Signature")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Signature", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Content-Sha256", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Date")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Date", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Credential")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Credential", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Security-Token")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Security-Token", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Algorithm")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Algorithm", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-SignedHeaders", valid_613816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613818: Call_ModifyEndpoint_613806; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified endpoint.
  ## 
  let valid = call_613818.validator(path, query, header, formData, body)
  let scheme = call_613818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613818.url(scheme.get, call_613818.host, call_613818.base,
                         call_613818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613818, url, valid)

proc call*(call_613819: Call_ModifyEndpoint_613806; body: JsonNode): Recallable =
  ## modifyEndpoint
  ## Modifies the specified endpoint.
  ##   body: JObject (required)
  var body_613820 = newJObject()
  if body != nil:
    body_613820 = body
  result = call_613819.call(nil, nil, nil, nil, body_613820)

var modifyEndpoint* = Call_ModifyEndpoint_613806(name: "modifyEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint",
    validator: validate_ModifyEndpoint_613807, base: "/", url: url_ModifyEndpoint_613808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEventSubscription_613821 = ref object of OpenApiRestCall_612658
proc url_ModifyEventSubscription_613823(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyEventSubscription_613822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an existing AWS DMS event notification subscription. 
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
  var valid_613824 = header.getOrDefault("X-Amz-Target")
  valid_613824 = validateParameter(valid_613824, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEventSubscription"))
  if valid_613824 != nil:
    section.add "X-Amz-Target", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Signature")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Signature", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Content-Sha256", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Date")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Date", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Credential")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Credential", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Security-Token")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Security-Token", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Algorithm")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Algorithm", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-SignedHeaders", valid_613831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613833: Call_ModifyEventSubscription_613821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing AWS DMS event notification subscription. 
  ## 
  let valid = call_613833.validator(path, query, header, formData, body)
  let scheme = call_613833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613833.url(scheme.get, call_613833.host, call_613833.base,
                         call_613833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613833, url, valid)

proc call*(call_613834: Call_ModifyEventSubscription_613821; body: JsonNode): Recallable =
  ## modifyEventSubscription
  ## Modifies an existing AWS DMS event notification subscription. 
  ##   body: JObject (required)
  var body_613835 = newJObject()
  if body != nil:
    body_613835 = body
  result = call_613834.call(nil, nil, nil, nil, body_613835)

var modifyEventSubscription* = Call_ModifyEventSubscription_613821(
    name: "modifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription",
    validator: validate_ModifyEventSubscription_613822, base: "/",
    url: url_ModifyEventSubscription_613823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationInstance_613836 = ref object of OpenApiRestCall_612658
proc url_ModifyReplicationInstance_613838(protocol: Scheme; host: string;
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

proc validate_ModifyReplicationInstance_613837(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
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
  var valid_613839 = header.getOrDefault("X-Amz-Target")
  valid_613839 = validateParameter(valid_613839, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationInstance"))
  if valid_613839 != nil:
    section.add "X-Amz-Target", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Signature")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Signature", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Content-Sha256", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Date")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Date", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Credential")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Credential", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Security-Token")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Security-Token", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Algorithm")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Algorithm", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-SignedHeaders", valid_613846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613848: Call_ModifyReplicationInstance_613836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ## 
  let valid = call_613848.validator(path, query, header, formData, body)
  let scheme = call_613848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613848.url(scheme.get, call_613848.host, call_613848.base,
                         call_613848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613848, url, valid)

proc call*(call_613849: Call_ModifyReplicationInstance_613836; body: JsonNode): Recallable =
  ## modifyReplicationInstance
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ##   body: JObject (required)
  var body_613850 = newJObject()
  if body != nil:
    body_613850 = body
  result = call_613849.call(nil, nil, nil, nil, body_613850)

var modifyReplicationInstance* = Call_ModifyReplicationInstance_613836(
    name: "modifyReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance",
    validator: validate_ModifyReplicationInstance_613837, base: "/",
    url: url_ModifyReplicationInstance_613838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationSubnetGroup_613851 = ref object of OpenApiRestCall_612658
proc url_ModifyReplicationSubnetGroup_613853(protocol: Scheme; host: string;
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

proc validate_ModifyReplicationSubnetGroup_613852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the settings for the specified replication subnet group.
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
  var valid_613854 = header.getOrDefault("X-Amz-Target")
  valid_613854 = validateParameter(valid_613854, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationSubnetGroup"))
  if valid_613854 != nil:
    section.add "X-Amz-Target", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Signature")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Signature", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Content-Sha256", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Date")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Date", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Credential")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Credential", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Security-Token")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Security-Token", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Algorithm")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Algorithm", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-SignedHeaders", valid_613861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613863: Call_ModifyReplicationSubnetGroup_613851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for the specified replication subnet group.
  ## 
  let valid = call_613863.validator(path, query, header, formData, body)
  let scheme = call_613863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613863.url(scheme.get, call_613863.host, call_613863.base,
                         call_613863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613863, url, valid)

proc call*(call_613864: Call_ModifyReplicationSubnetGroup_613851; body: JsonNode): Recallable =
  ## modifyReplicationSubnetGroup
  ## Modifies the settings for the specified replication subnet group.
  ##   body: JObject (required)
  var body_613865 = newJObject()
  if body != nil:
    body_613865 = body
  result = call_613864.call(nil, nil, nil, nil, body_613865)

var modifyReplicationSubnetGroup* = Call_ModifyReplicationSubnetGroup_613851(
    name: "modifyReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup",
    validator: validate_ModifyReplicationSubnetGroup_613852, base: "/",
    url: url_ModifyReplicationSubnetGroup_613853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationTask_613866 = ref object of OpenApiRestCall_612658
proc url_ModifyReplicationTask_613868(protocol: Scheme; host: string; base: string;
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

proc validate_ModifyReplicationTask_613867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
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
  var valid_613869 = header.getOrDefault("X-Amz-Target")
  valid_613869 = validateParameter(valid_613869, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationTask"))
  if valid_613869 != nil:
    section.add "X-Amz-Target", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Signature")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Signature", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Content-Sha256", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Date")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Date", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Credential")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Credential", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Security-Token")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Security-Token", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Algorithm")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Algorithm", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-SignedHeaders", valid_613876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613878: Call_ModifyReplicationTask_613866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ## 
  let valid = call_613878.validator(path, query, header, formData, body)
  let scheme = call_613878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613878.url(scheme.get, call_613878.host, call_613878.base,
                         call_613878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613878, url, valid)

proc call*(call_613879: Call_ModifyReplicationTask_613866; body: JsonNode): Recallable =
  ## modifyReplicationTask
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613880 = newJObject()
  if body != nil:
    body_613880 = body
  result = call_613879.call(nil, nil, nil, nil, body_613880)

var modifyReplicationTask* = Call_ModifyReplicationTask_613866(
    name: "modifyReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask",
    validator: validate_ModifyReplicationTask_613867, base: "/",
    url: url_ModifyReplicationTask_613868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootReplicationInstance_613881 = ref object of OpenApiRestCall_612658
proc url_RebootReplicationInstance_613883(protocol: Scheme; host: string;
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

proc validate_RebootReplicationInstance_613882(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
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
  var valid_613884 = header.getOrDefault("X-Amz-Target")
  valid_613884 = validateParameter(valid_613884, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RebootReplicationInstance"))
  if valid_613884 != nil:
    section.add "X-Amz-Target", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Signature")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Signature", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Content-Sha256", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Date")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Date", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Credential")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Credential", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Security-Token")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Security-Token", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Algorithm")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Algorithm", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-SignedHeaders", valid_613891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613893: Call_RebootReplicationInstance_613881; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ## 
  let valid = call_613893.validator(path, query, header, formData, body)
  let scheme = call_613893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613893.url(scheme.get, call_613893.host, call_613893.base,
                         call_613893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613893, url, valid)

proc call*(call_613894: Call_RebootReplicationInstance_613881; body: JsonNode): Recallable =
  ## rebootReplicationInstance
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ##   body: JObject (required)
  var body_613895 = newJObject()
  if body != nil:
    body_613895 = body
  result = call_613894.call(nil, nil, nil, nil, body_613895)

var rebootReplicationInstance* = Call_RebootReplicationInstance_613881(
    name: "rebootReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance",
    validator: validate_RebootReplicationInstance_613882, base: "/",
    url: url_RebootReplicationInstance_613883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshSchemas_613896 = ref object of OpenApiRestCall_612658
proc url_RefreshSchemas_613898(protocol: Scheme; host: string; base: string;
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

proc validate_RefreshSchemas_613897(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
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
  var valid_613899 = header.getOrDefault("X-Amz-Target")
  valid_613899 = validateParameter(valid_613899, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RefreshSchemas"))
  if valid_613899 != nil:
    section.add "X-Amz-Target", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Signature")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Signature", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Content-Sha256", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Date")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Date", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Credential")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Credential", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Security-Token")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Security-Token", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-Algorithm")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-Algorithm", valid_613905
  var valid_613906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "X-Amz-SignedHeaders", valid_613906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613908: Call_RefreshSchemas_613896; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ## 
  let valid = call_613908.validator(path, query, header, formData, body)
  let scheme = call_613908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613908.url(scheme.get, call_613908.host, call_613908.base,
                         call_613908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613908, url, valid)

proc call*(call_613909: Call_RefreshSchemas_613896; body: JsonNode): Recallable =
  ## refreshSchemas
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ##   body: JObject (required)
  var body_613910 = newJObject()
  if body != nil:
    body_613910 = body
  result = call_613909.call(nil, nil, nil, nil, body_613910)

var refreshSchemas* = Call_RefreshSchemas_613896(name: "refreshSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas",
    validator: validate_RefreshSchemas_613897, base: "/", url: url_RefreshSchemas_613898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReloadTables_613911 = ref object of OpenApiRestCall_612658
proc url_ReloadTables_613913(protocol: Scheme; host: string; base: string;
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

proc validate_ReloadTables_613912(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Reloads the target database table with the source data. 
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
  var valid_613914 = header.getOrDefault("X-Amz-Target")
  valid_613914 = validateParameter(valid_613914, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ReloadTables"))
  if valid_613914 != nil:
    section.add "X-Amz-Target", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Signature")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Signature", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Content-Sha256", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Date")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Date", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Credential")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Credential", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Security-Token")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Security-Token", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Algorithm")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Algorithm", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-SignedHeaders", valid_613921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613923: Call_ReloadTables_613911; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reloads the target database table with the source data. 
  ## 
  let valid = call_613923.validator(path, query, header, formData, body)
  let scheme = call_613923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613923.url(scheme.get, call_613923.host, call_613923.base,
                         call_613923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613923, url, valid)

proc call*(call_613924: Call_ReloadTables_613911; body: JsonNode): Recallable =
  ## reloadTables
  ## Reloads the target database table with the source data. 
  ##   body: JObject (required)
  var body_613925 = newJObject()
  if body != nil:
    body_613925 = body
  result = call_613924.call(nil, nil, nil, nil, body_613925)

var reloadTables* = Call_ReloadTables_613911(name: "reloadTables",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ReloadTables",
    validator: validate_ReloadTables_613912, base: "/", url: url_ReloadTables_613913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_613926 = ref object of OpenApiRestCall_612658
proc url_RemoveTagsFromResource_613928(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveTagsFromResource_613927(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes metadata tags from a DMS resource.
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
  var valid_613929 = header.getOrDefault("X-Amz-Target")
  valid_613929 = validateParameter(valid_613929, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RemoveTagsFromResource"))
  if valid_613929 != nil:
    section.add "X-Amz-Target", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Signature")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Signature", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Content-Sha256", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Date")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Date", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Credential")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Credential", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Security-Token")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Security-Token", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-Algorithm")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Algorithm", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-SignedHeaders", valid_613936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613938: Call_RemoveTagsFromResource_613926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a DMS resource.
  ## 
  let valid = call_613938.validator(path, query, header, formData, body)
  let scheme = call_613938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613938.url(scheme.get, call_613938.host, call_613938.base,
                         call_613938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613938, url, valid)

proc call*(call_613939: Call_RemoveTagsFromResource_613926; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes metadata tags from a DMS resource.
  ##   body: JObject (required)
  var body_613940 = newJObject()
  if body != nil:
    body_613940 = body
  result = call_613939.call(nil, nil, nil, nil, body_613940)

var removeTagsFromResource* = Call_RemoveTagsFromResource_613926(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_613927, base: "/",
    url: url_RemoveTagsFromResource_613928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTask_613941 = ref object of OpenApiRestCall_612658
proc url_StartReplicationTask_613943(protocol: Scheme; host: string; base: string;
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

proc validate_StartReplicationTask_613942(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
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
  var valid_613944 = header.getOrDefault("X-Amz-Target")
  valid_613944 = validateParameter(valid_613944, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTask"))
  if valid_613944 != nil:
    section.add "X-Amz-Target", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Signature")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Signature", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Content-Sha256", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Date")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Date", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Credential")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Credential", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-Security-Token")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Security-Token", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-Algorithm")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Algorithm", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-SignedHeaders", valid_613951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613953: Call_StartReplicationTask_613941; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_613953.validator(path, query, header, formData, body)
  let scheme = call_613953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613953.url(scheme.get, call_613953.host, call_613953.base,
                         call_613953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613953, url, valid)

proc call*(call_613954: Call_StartReplicationTask_613941; body: JsonNode): Recallable =
  ## startReplicationTask
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_613955 = newJObject()
  if body != nil:
    body_613955 = body
  result = call_613954.call(nil, nil, nil, nil, body_613955)

var startReplicationTask* = Call_StartReplicationTask_613941(
    name: "startReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask",
    validator: validate_StartReplicationTask_613942, base: "/",
    url: url_StartReplicationTask_613943, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTaskAssessment_613956 = ref object of OpenApiRestCall_612658
proc url_StartReplicationTaskAssessment_613958(protocol: Scheme; host: string;
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

proc validate_StartReplicationTaskAssessment_613957(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Starts the replication task assessment for unsupported data types in the source database. 
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
  var valid_613959 = header.getOrDefault("X-Amz-Target")
  valid_613959 = validateParameter(valid_613959, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTaskAssessment"))
  if valid_613959 != nil:
    section.add "X-Amz-Target", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Signature")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Signature", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Content-Sha256", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Date")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Date", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Credential")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Credential", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Security-Token")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Security-Token", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-Algorithm")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-Algorithm", valid_613965
  var valid_613966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613966 = validateParameter(valid_613966, JString, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "X-Amz-SignedHeaders", valid_613966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613968: Call_StartReplicationTaskAssessment_613956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ## 
  let valid = call_613968.validator(path, query, header, formData, body)
  let scheme = call_613968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613968.url(scheme.get, call_613968.host, call_613968.base,
                         call_613968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613968, url, valid)

proc call*(call_613969: Call_StartReplicationTaskAssessment_613956; body: JsonNode): Recallable =
  ## startReplicationTaskAssessment
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ##   body: JObject (required)
  var body_613970 = newJObject()
  if body != nil:
    body_613970 = body
  result = call_613969.call(nil, nil, nil, nil, body_613970)

var startReplicationTaskAssessment* = Call_StartReplicationTaskAssessment_613956(
    name: "startReplicationTaskAssessment", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment",
    validator: validate_StartReplicationTaskAssessment_613957, base: "/",
    url: url_StartReplicationTaskAssessment_613958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopReplicationTask_613971 = ref object of OpenApiRestCall_612658
proc url_StopReplicationTask_613973(protocol: Scheme; host: string; base: string;
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

proc validate_StopReplicationTask_613972(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Stops the replication task.</p> <p/>
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
  var valid_613974 = header.getOrDefault("X-Amz-Target")
  valid_613974 = validateParameter(valid_613974, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StopReplicationTask"))
  if valid_613974 != nil:
    section.add "X-Amz-Target", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Signature")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Signature", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Content-Sha256", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Date")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Date", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Credential")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Credential", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Security-Token")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Security-Token", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Algorithm")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Algorithm", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-SignedHeaders", valid_613981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613983: Call_StopReplicationTask_613971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops the replication task.</p> <p/>
  ## 
  let valid = call_613983.validator(path, query, header, formData, body)
  let scheme = call_613983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613983.url(scheme.get, call_613983.host, call_613983.base,
                         call_613983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613983, url, valid)

proc call*(call_613984: Call_StopReplicationTask_613971; body: JsonNode): Recallable =
  ## stopReplicationTask
  ## <p>Stops the replication task.</p> <p/>
  ##   body: JObject (required)
  var body_613985 = newJObject()
  if body != nil:
    body_613985 = body
  result = call_613984.call(nil, nil, nil, nil, body_613985)

var stopReplicationTask* = Call_StopReplicationTask_613971(
    name: "stopReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask",
    validator: validate_StopReplicationTask_613972, base: "/",
    url: url_StopReplicationTask_613973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestConnection_613986 = ref object of OpenApiRestCall_612658
proc url_TestConnection_613988(protocol: Scheme; host: string; base: string;
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

proc validate_TestConnection_613987(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Tests the connection between the replication instance and the endpoint.
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
  var valid_613989 = header.getOrDefault("X-Amz-Target")
  valid_613989 = validateParameter(valid_613989, JString, required = true, default = newJString(
      "AmazonDMSv20160101.TestConnection"))
  if valid_613989 != nil:
    section.add "X-Amz-Target", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Signature")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Signature", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Content-Sha256", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Date")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Date", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Credential")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Credential", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Security-Token")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Security-Token", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Algorithm")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Algorithm", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-SignedHeaders", valid_613996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613998: Call_TestConnection_613986; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the connection between the replication instance and the endpoint.
  ## 
  let valid = call_613998.validator(path, query, header, formData, body)
  let scheme = call_613998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613998.url(scheme.get, call_613998.host, call_613998.base,
                         call_613998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613998, url, valid)

proc call*(call_613999: Call_TestConnection_613986; body: JsonNode): Recallable =
  ## testConnection
  ## Tests the connection between the replication instance and the endpoint.
  ##   body: JObject (required)
  var body_614000 = newJObject()
  if body != nil:
    body_614000 = body
  result = call_613999.call(nil, nil, nil, nil, body_614000)

var testConnection* = Call_TestConnection_613986(name: "testConnection",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.TestConnection",
    validator: validate_TestConnection_613987, base: "/", url: url_TestConnection_613988,
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
