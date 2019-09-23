
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600437): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_600774 = ref object of OpenApiRestCall_600437
proc url_AddTagsToResource_600776(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTagsToResource_600775(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600903 = header.getOrDefault("X-Amz-Target")
  valid_600903 = validateParameter(valid_600903, JString, required = true, default = newJString(
      "AmazonDMSv20160101.AddTagsToResource"))
  if valid_600903 != nil:
    section.add "X-Amz-Target", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Content-Sha256", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Algorithm")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Algorithm", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Signature")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Signature", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-SignedHeaders", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Credential")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Credential", valid_600908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600932: Call_AddTagsToResource_600774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ## 
  let valid = call_600932.validator(path, query, header, formData, body)
  let scheme = call_600932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600932.url(scheme.get, call_600932.host, call_600932.base,
                         call_600932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600932, url, valid)

proc call*(call_601003: Call_AddTagsToResource_600774; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ##   body: JObject (required)
  var body_601004 = newJObject()
  if body != nil:
    body_601004 = body
  result = call_601003.call(nil, nil, nil, nil, body_601004)

var addTagsToResource* = Call_AddTagsToResource_600774(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource",
    validator: validate_AddTagsToResource_600775, base: "/",
    url: url_AddTagsToResource_600776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplyPendingMaintenanceAction_601043 = ref object of OpenApiRestCall_600437
proc url_ApplyPendingMaintenanceAction_601045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ApplyPendingMaintenanceAction_601044(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601048 = header.getOrDefault("X-Amz-Target")
  valid_601048 = validateParameter(valid_601048, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ApplyPendingMaintenanceAction"))
  if valid_601048 != nil:
    section.add "X-Amz-Target", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Content-Sha256", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Algorithm")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Algorithm", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Signature")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Signature", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-SignedHeaders", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Credential")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Credential", valid_601053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_ApplyPendingMaintenanceAction_601043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_ApplyPendingMaintenanceAction_601043; body: JsonNode): Recallable =
  ## applyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ##   body: JObject (required)
  var body_601057 = newJObject()
  if body != nil:
    body_601057 = body
  result = call_601056.call(nil, nil, nil, nil, body_601057)

var applyPendingMaintenanceAction* = Call_ApplyPendingMaintenanceAction_601043(
    name: "applyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction",
    validator: validate_ApplyPendingMaintenanceAction_601044, base: "/",
    url: url_ApplyPendingMaintenanceAction_601045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_601058 = ref object of OpenApiRestCall_600437
proc url_CreateEndpoint_601060(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEndpoint_601059(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601063 = header.getOrDefault("X-Amz-Target")
  valid_601063 = validateParameter(valid_601063, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEndpoint"))
  if valid_601063 != nil:
    section.add "X-Amz-Target", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Content-Sha256", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Algorithm")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Algorithm", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Signature")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Signature", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-SignedHeaders", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Credential")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Credential", valid_601068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601070: Call_CreateEndpoint_601058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint using the provided settings.
  ## 
  let valid = call_601070.validator(path, query, header, formData, body)
  let scheme = call_601070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601070.url(scheme.get, call_601070.host, call_601070.base,
                         call_601070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601070, url, valid)

proc call*(call_601071: Call_CreateEndpoint_601058; body: JsonNode): Recallable =
  ## createEndpoint
  ## Creates an endpoint using the provided settings.
  ##   body: JObject (required)
  var body_601072 = newJObject()
  if body != nil:
    body_601072 = body
  result = call_601071.call(nil, nil, nil, nil, body_601072)

var createEndpoint* = Call_CreateEndpoint_601058(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint",
    validator: validate_CreateEndpoint_601059, base: "/", url: url_CreateEndpoint_601060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSubscription_601073 = ref object of OpenApiRestCall_600437
proc url_CreateEventSubscription_601075(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEventSubscription_601074(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601076 = header.getOrDefault("X-Amz-Date")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Date", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Security-Token")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Security-Token", valid_601077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601078 = header.getOrDefault("X-Amz-Target")
  valid_601078 = validateParameter(valid_601078, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEventSubscription"))
  if valid_601078 != nil:
    section.add "X-Amz-Target", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Content-Sha256", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Algorithm")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Algorithm", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Signature")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Signature", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-SignedHeaders", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Credential")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Credential", valid_601083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601085: Call_CreateEventSubscription_601073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_601085.validator(path, query, header, formData, body)
  let scheme = call_601085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601085.url(scheme.get, call_601085.host, call_601085.base,
                         call_601085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601085, url, valid)

proc call*(call_601086: Call_CreateEventSubscription_601073; body: JsonNode): Recallable =
  ## createEventSubscription
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_601087 = newJObject()
  if body != nil:
    body_601087 = body
  result = call_601086.call(nil, nil, nil, nil, body_601087)

var createEventSubscription* = Call_CreateEventSubscription_601073(
    name: "createEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription",
    validator: validate_CreateEventSubscription_601074, base: "/",
    url: url_CreateEventSubscription_601075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationInstance_601088 = ref object of OpenApiRestCall_600437
proc url_CreateReplicationInstance_601090(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateReplicationInstance_601089(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates the replication instance using the specified parameters.
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
  var valid_601091 = header.getOrDefault("X-Amz-Date")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Date", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Security-Token")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Security-Token", valid_601092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601093 = header.getOrDefault("X-Amz-Target")
  valid_601093 = validateParameter(valid_601093, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationInstance"))
  if valid_601093 != nil:
    section.add "X-Amz-Target", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_CreateReplicationInstance_601088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the replication instance using the specified parameters.
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601100, url, valid)

proc call*(call_601101: Call_CreateReplicationInstance_601088; body: JsonNode): Recallable =
  ## createReplicationInstance
  ## Creates the replication instance using the specified parameters.
  ##   body: JObject (required)
  var body_601102 = newJObject()
  if body != nil:
    body_601102 = body
  result = call_601101.call(nil, nil, nil, nil, body_601102)

var createReplicationInstance* = Call_CreateReplicationInstance_601088(
    name: "createReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance",
    validator: validate_CreateReplicationInstance_601089, base: "/",
    url: url_CreateReplicationInstance_601090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationSubnetGroup_601103 = ref object of OpenApiRestCall_600437
proc url_CreateReplicationSubnetGroup_601105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateReplicationSubnetGroup_601104(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601106 = header.getOrDefault("X-Amz-Date")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Date", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Security-Token")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Security-Token", valid_601107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601108 = header.getOrDefault("X-Amz-Target")
  valid_601108 = validateParameter(valid_601108, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationSubnetGroup"))
  if valid_601108 != nil:
    section.add "X-Amz-Target", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Content-Sha256", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Algorithm")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Algorithm", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Signature")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Signature", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-SignedHeaders", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Credential")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Credential", valid_601113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_CreateReplicationSubnetGroup_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_CreateReplicationSubnetGroup_601103; body: JsonNode): Recallable =
  ## createReplicationSubnetGroup
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ##   body: JObject (required)
  var body_601117 = newJObject()
  if body != nil:
    body_601117 = body
  result = call_601116.call(nil, nil, nil, nil, body_601117)

var createReplicationSubnetGroup* = Call_CreateReplicationSubnetGroup_601103(
    name: "createReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup",
    validator: validate_CreateReplicationSubnetGroup_601104, base: "/",
    url: url_CreateReplicationSubnetGroup_601105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationTask_601118 = ref object of OpenApiRestCall_600437
proc url_CreateReplicationTask_601120(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateReplicationTask_601119(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601121 = header.getOrDefault("X-Amz-Date")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Date", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Security-Token")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Security-Token", valid_601122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601123 = header.getOrDefault("X-Amz-Target")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationTask"))
  if valid_601123 != nil:
    section.add "X-Amz-Target", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601130: Call_CreateReplicationTask_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication task using the specified parameters.
  ## 
  let valid = call_601130.validator(path, query, header, formData, body)
  let scheme = call_601130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601130.url(scheme.get, call_601130.host, call_601130.base,
                         call_601130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601130, url, valid)

proc call*(call_601131: Call_CreateReplicationTask_601118; body: JsonNode): Recallable =
  ## createReplicationTask
  ## Creates a replication task using the specified parameters.
  ##   body: JObject (required)
  var body_601132 = newJObject()
  if body != nil:
    body_601132 = body
  result = call_601131.call(nil, nil, nil, nil, body_601132)

var createReplicationTask* = Call_CreateReplicationTask_601118(
    name: "createReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask",
    validator: validate_CreateReplicationTask_601119, base: "/",
    url: url_CreateReplicationTask_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificate_601133 = ref object of OpenApiRestCall_600437
proc url_DeleteCertificate_601135(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCertificate_601134(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601136 = header.getOrDefault("X-Amz-Date")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Date", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Security-Token")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Security-Token", valid_601137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601138 = header.getOrDefault("X-Amz-Target")
  valid_601138 = validateParameter(valid_601138, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteCertificate"))
  if valid_601138 != nil:
    section.add "X-Amz-Target", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_DeleteCertificate_601133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified certificate. 
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_DeleteCertificate_601133; body: JsonNode): Recallable =
  ## deleteCertificate
  ## Deletes the specified certificate. 
  ##   body: JObject (required)
  var body_601147 = newJObject()
  if body != nil:
    body_601147 = body
  result = call_601146.call(nil, nil, nil, nil, body_601147)

var deleteCertificate* = Call_DeleteCertificate_601133(name: "deleteCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate",
    validator: validate_DeleteCertificate_601134, base: "/",
    url: url_DeleteCertificate_601135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_601148 = ref object of OpenApiRestCall_600437
proc url_DeleteEndpoint_601150(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEndpoint_601149(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601151 = header.getOrDefault("X-Amz-Date")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Date", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Security-Token")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Security-Token", valid_601152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601153 = header.getOrDefault("X-Amz-Target")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEndpoint"))
  if valid_601153 != nil:
    section.add "X-Amz-Target", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_DeleteEndpoint_601148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_DeleteEndpoint_601148; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var deleteEndpoint* = Call_DeleteEndpoint_601148(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint",
    validator: validate_DeleteEndpoint_601149, base: "/", url: url_DeleteEndpoint_601150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSubscription_601163 = ref object of OpenApiRestCall_600437
proc url_DeleteEventSubscription_601165(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEventSubscription_601164(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601168 = header.getOrDefault("X-Amz-Target")
  valid_601168 = validateParameter(valid_601168, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEventSubscription"))
  if valid_601168 != nil:
    section.add "X-Amz-Target", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_DeleteEventSubscription_601163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an AWS DMS event subscription. 
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601175, url, valid)

proc call*(call_601176: Call_DeleteEventSubscription_601163; body: JsonNode): Recallable =
  ## deleteEventSubscription
  ##  Deletes an AWS DMS event subscription. 
  ##   body: JObject (required)
  var body_601177 = newJObject()
  if body != nil:
    body_601177 = body
  result = call_601176.call(nil, nil, nil, nil, body_601177)

var deleteEventSubscription* = Call_DeleteEventSubscription_601163(
    name: "deleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription",
    validator: validate_DeleteEventSubscription_601164, base: "/",
    url: url_DeleteEventSubscription_601165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationInstance_601178 = ref object of OpenApiRestCall_600437
proc url_DeleteReplicationInstance_601180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteReplicationInstance_601179(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601181 = header.getOrDefault("X-Amz-Date")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Date", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Security-Token")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Security-Token", valid_601182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601183 = header.getOrDefault("X-Amz-Target")
  valid_601183 = validateParameter(valid_601183, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationInstance"))
  if valid_601183 != nil:
    section.add "X-Amz-Target", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_DeleteReplicationInstance_601178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ## 
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601190, url, valid)

proc call*(call_601191: Call_DeleteReplicationInstance_601178; body: JsonNode): Recallable =
  ## deleteReplicationInstance
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ##   body: JObject (required)
  var body_601192 = newJObject()
  if body != nil:
    body_601192 = body
  result = call_601191.call(nil, nil, nil, nil, body_601192)

var deleteReplicationInstance* = Call_DeleteReplicationInstance_601178(
    name: "deleteReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance",
    validator: validate_DeleteReplicationInstance_601179, base: "/",
    url: url_DeleteReplicationInstance_601180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationSubnetGroup_601193 = ref object of OpenApiRestCall_600437
proc url_DeleteReplicationSubnetGroup_601195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteReplicationSubnetGroup_601194(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601196 = header.getOrDefault("X-Amz-Date")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Date", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Security-Token")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Security-Token", valid_601197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601198 = header.getOrDefault("X-Amz-Target")
  valid_601198 = validateParameter(valid_601198, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationSubnetGroup"))
  if valid_601198 != nil:
    section.add "X-Amz-Target", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_DeleteReplicationSubnetGroup_601193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subnet group.
  ## 
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601205, url, valid)

proc call*(call_601206: Call_DeleteReplicationSubnetGroup_601193; body: JsonNode): Recallable =
  ## deleteReplicationSubnetGroup
  ## Deletes a subnet group.
  ##   body: JObject (required)
  var body_601207 = newJObject()
  if body != nil:
    body_601207 = body
  result = call_601206.call(nil, nil, nil, nil, body_601207)

var deleteReplicationSubnetGroup* = Call_DeleteReplicationSubnetGroup_601193(
    name: "deleteReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup",
    validator: validate_DeleteReplicationSubnetGroup_601194, base: "/",
    url: url_DeleteReplicationSubnetGroup_601195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationTask_601208 = ref object of OpenApiRestCall_600437
proc url_DeleteReplicationTask_601210(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteReplicationTask_601209(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601211 = header.getOrDefault("X-Amz-Date")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Date", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Security-Token")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Security-Token", valid_601212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601213 = header.getOrDefault("X-Amz-Target")
  valid_601213 = validateParameter(valid_601213, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationTask"))
  if valid_601213 != nil:
    section.add "X-Amz-Target", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Content-Sha256", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Algorithm")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Algorithm", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Signature")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Signature", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-SignedHeaders", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Credential")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Credential", valid_601218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601220: Call_DeleteReplicationTask_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified replication task.
  ## 
  let valid = call_601220.validator(path, query, header, formData, body)
  let scheme = call_601220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601220.url(scheme.get, call_601220.host, call_601220.base,
                         call_601220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601220, url, valid)

proc call*(call_601221: Call_DeleteReplicationTask_601208; body: JsonNode): Recallable =
  ## deleteReplicationTask
  ## Deletes the specified replication task.
  ##   body: JObject (required)
  var body_601222 = newJObject()
  if body != nil:
    body_601222 = body
  result = call_601221.call(nil, nil, nil, nil, body_601222)

var deleteReplicationTask* = Call_DeleteReplicationTask_601208(
    name: "deleteReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask",
    validator: validate_DeleteReplicationTask_601209, base: "/",
    url: url_DeleteReplicationTask_601210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_601223 = ref object of OpenApiRestCall_600437
proc url_DescribeAccountAttributes_601225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAccountAttributes_601224(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601226 = header.getOrDefault("X-Amz-Date")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Date", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Security-Token")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Security-Token", valid_601227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601228 = header.getOrDefault("X-Amz-Target")
  valid_601228 = validateParameter(valid_601228, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeAccountAttributes"))
  if valid_601228 != nil:
    section.add "X-Amz-Target", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Content-Sha256", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Algorithm")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Algorithm", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Signature")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Signature", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-SignedHeaders", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Credential")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Credential", valid_601233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_DescribeAccountAttributes_601223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_DescribeAccountAttributes_601223; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ##   body: JObject (required)
  var body_601237 = newJObject()
  if body != nil:
    body_601237 = body
  result = call_601236.call(nil, nil, nil, nil, body_601237)

var describeAccountAttributes* = Call_DescribeAccountAttributes_601223(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_601224, base: "/",
    url: url_DescribeAccountAttributes_601225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificates_601238 = ref object of OpenApiRestCall_600437
proc url_DescribeCertificates_601240(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCertificates_601239(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides a description of the certificate.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601241 = query.getOrDefault("MaxRecords")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "MaxRecords", valid_601241
  var valid_601242 = query.getOrDefault("Marker")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "Marker", valid_601242
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
      "AmazonDMSv20160101.DescribeCertificates"))
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

proc call*(call_601252: Call_DescribeCertificates_601238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a description of the certificate.
  ## 
  let valid = call_601252.validator(path, query, header, formData, body)
  let scheme = call_601252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601252.url(scheme.get, call_601252.host, call_601252.base,
                         call_601252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601252, url, valid)

proc call*(call_601253: Call_DescribeCertificates_601238; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeCertificates
  ## Provides a description of the certificate.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601254 = newJObject()
  var body_601255 = newJObject()
  add(query_601254, "MaxRecords", newJString(MaxRecords))
  add(query_601254, "Marker", newJString(Marker))
  if body != nil:
    body_601255 = body
  result = call_601253.call(nil, query_601254, nil, nil, body_601255)

var describeCertificates* = Call_DescribeCertificates_601238(
    name: "describeCertificates", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates",
    validator: validate_DescribeCertificates_601239, base: "/",
    url: url_DescribeCertificates_601240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_601257 = ref object of OpenApiRestCall_600437
proc url_DescribeConnections_601259(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConnections_601258(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601260 = query.getOrDefault("MaxRecords")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "MaxRecords", valid_601260
  var valid_601261 = query.getOrDefault("Marker")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "Marker", valid_601261
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
  var valid_601262 = header.getOrDefault("X-Amz-Date")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Date", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Security-Token")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Security-Token", valid_601263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601264 = header.getOrDefault("X-Amz-Target")
  valid_601264 = validateParameter(valid_601264, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeConnections"))
  if valid_601264 != nil:
    section.add "X-Amz-Target", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Content-Sha256", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Algorithm")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Algorithm", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Signature")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Signature", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-SignedHeaders", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Credential")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Credential", valid_601269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601271: Call_DescribeConnections_601257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ## 
  let valid = call_601271.validator(path, query, header, formData, body)
  let scheme = call_601271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601271.url(scheme.get, call_601271.host, call_601271.base,
                         call_601271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601271, url, valid)

proc call*(call_601272: Call_DescribeConnections_601257; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeConnections
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601273 = newJObject()
  var body_601274 = newJObject()
  add(query_601273, "MaxRecords", newJString(MaxRecords))
  add(query_601273, "Marker", newJString(Marker))
  if body != nil:
    body_601274 = body
  result = call_601272.call(nil, query_601273, nil, nil, body_601274)

var describeConnections* = Call_DescribeConnections_601257(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeConnections",
    validator: validate_DescribeConnections_601258, base: "/",
    url: url_DescribeConnections_601259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointTypes_601275 = ref object of OpenApiRestCall_600437
proc url_DescribeEndpointTypes_601277(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpointTypes_601276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the type of endpoints available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601278 = query.getOrDefault("MaxRecords")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "MaxRecords", valid_601278
  var valid_601279 = query.getOrDefault("Marker")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "Marker", valid_601279
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
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpointTypes"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_DescribeEndpointTypes_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the type of endpoints available.
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_DescribeEndpointTypes_601275; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpointTypes
  ## Returns information about the type of endpoints available.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601291 = newJObject()
  var body_601292 = newJObject()
  add(query_601291, "MaxRecords", newJString(MaxRecords))
  add(query_601291, "Marker", newJString(Marker))
  if body != nil:
    body_601292 = body
  result = call_601290.call(nil, query_601291, nil, nil, body_601292)

var describeEndpointTypes* = Call_DescribeEndpointTypes_601275(
    name: "describeEndpointTypes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes",
    validator: validate_DescribeEndpointTypes_601276, base: "/",
    url: url_DescribeEndpointTypes_601277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_601293 = ref object of OpenApiRestCall_600437
proc url_DescribeEndpoints_601295(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpoints_601294(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about the endpoints for your account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601296 = query.getOrDefault("MaxRecords")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "MaxRecords", valid_601296
  var valid_601297 = query.getOrDefault("Marker")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "Marker", valid_601297
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
  var valid_601298 = header.getOrDefault("X-Amz-Date")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Date", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Security-Token")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Security-Token", valid_601299
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601300 = header.getOrDefault("X-Amz-Target")
  valid_601300 = validateParameter(valid_601300, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpoints"))
  if valid_601300 != nil:
    section.add "X-Amz-Target", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Content-Sha256", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Algorithm")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Algorithm", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Signature")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Signature", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-SignedHeaders", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Credential")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Credential", valid_601305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601307: Call_DescribeEndpoints_601293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the endpoints for your account in the current region.
  ## 
  let valid = call_601307.validator(path, query, header, formData, body)
  let scheme = call_601307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601307.url(scheme.get, call_601307.host, call_601307.base,
                         call_601307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601307, url, valid)

proc call*(call_601308: Call_DescribeEndpoints_601293; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpoints
  ## Returns information about the endpoints for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601309 = newJObject()
  var body_601310 = newJObject()
  add(query_601309, "MaxRecords", newJString(MaxRecords))
  add(query_601309, "Marker", newJString(Marker))
  if body != nil:
    body_601310 = body
  result = call_601308.call(nil, query_601309, nil, nil, body_601310)

var describeEndpoints* = Call_DescribeEndpoints_601293(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints",
    validator: validate_DescribeEndpoints_601294, base: "/",
    url: url_DescribeEndpoints_601295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventCategories_601311 = ref object of OpenApiRestCall_600437
proc url_DescribeEventCategories_601313(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEventCategories_601312(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601314 = header.getOrDefault("X-Amz-Date")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Date", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Security-Token")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Security-Token", valid_601315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601316 = header.getOrDefault("X-Amz-Target")
  valid_601316 = validateParameter(valid_601316, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventCategories"))
  if valid_601316 != nil:
    section.add "X-Amz-Target", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Content-Sha256", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Algorithm")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Algorithm", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Signature")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Signature", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-SignedHeaders", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Credential")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Credential", valid_601321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601323: Call_DescribeEventCategories_601311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ## 
  let valid = call_601323.validator(path, query, header, formData, body)
  let scheme = call_601323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601323.url(scheme.get, call_601323.host, call_601323.base,
                         call_601323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601323, url, valid)

proc call*(call_601324: Call_DescribeEventCategories_601311; body: JsonNode): Recallable =
  ## describeEventCategories
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ##   body: JObject (required)
  var body_601325 = newJObject()
  if body != nil:
    body_601325 = body
  result = call_601324.call(nil, nil, nil, nil, body_601325)

var describeEventCategories* = Call_DescribeEventCategories_601311(
    name: "describeEventCategories", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories",
    validator: validate_DescribeEventCategories_601312, base: "/",
    url: url_DescribeEventCategories_601313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventSubscriptions_601326 = ref object of OpenApiRestCall_600437
proc url_DescribeEventSubscriptions_601328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEventSubscriptions_601327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601329 = query.getOrDefault("MaxRecords")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "MaxRecords", valid_601329
  var valid_601330 = query.getOrDefault("Marker")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "Marker", valid_601330
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
  var valid_601331 = header.getOrDefault("X-Amz-Date")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Date", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Security-Token")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Security-Token", valid_601332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601333 = header.getOrDefault("X-Amz-Target")
  valid_601333 = validateParameter(valid_601333, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventSubscriptions"))
  if valid_601333 != nil:
    section.add "X-Amz-Target", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Content-Sha256", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Algorithm")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Algorithm", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Signature")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Signature", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-SignedHeaders", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Credential")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Credential", valid_601338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601340: Call_DescribeEventSubscriptions_601326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ## 
  let valid = call_601340.validator(path, query, header, formData, body)
  let scheme = call_601340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601340.url(scheme.get, call_601340.host, call_601340.base,
                         call_601340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601340, url, valid)

proc call*(call_601341: Call_DescribeEventSubscriptions_601326; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEventSubscriptions
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601342 = newJObject()
  var body_601343 = newJObject()
  add(query_601342, "MaxRecords", newJString(MaxRecords))
  add(query_601342, "Marker", newJString(Marker))
  if body != nil:
    body_601343 = body
  result = call_601341.call(nil, query_601342, nil, nil, body_601343)

var describeEventSubscriptions* = Call_DescribeEventSubscriptions_601326(
    name: "describeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions",
    validator: validate_DescribeEventSubscriptions_601327, base: "/",
    url: url_DescribeEventSubscriptions_601328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_601344 = ref object of OpenApiRestCall_600437
proc url_DescribeEvents_601346(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEvents_601345(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601347 = query.getOrDefault("MaxRecords")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "MaxRecords", valid_601347
  var valid_601348 = query.getOrDefault("Marker")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "Marker", valid_601348
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
  var valid_601349 = header.getOrDefault("X-Amz-Date")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Date", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Security-Token")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Security-Token", valid_601350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601351 = header.getOrDefault("X-Amz-Target")
  valid_601351 = validateParameter(valid_601351, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEvents"))
  if valid_601351 != nil:
    section.add "X-Amz-Target", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Content-Sha256", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Algorithm")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Algorithm", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Signature")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Signature", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-SignedHeaders", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Credential")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Credential", valid_601356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601358: Call_DescribeEvents_601344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ## 
  let valid = call_601358.validator(path, query, header, formData, body)
  let scheme = call_601358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601358.url(scheme.get, call_601358.host, call_601358.base,
                         call_601358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601358, url, valid)

proc call*(call_601359: Call_DescribeEvents_601344; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEvents
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601360 = newJObject()
  var body_601361 = newJObject()
  add(query_601360, "MaxRecords", newJString(MaxRecords))
  add(query_601360, "Marker", newJString(Marker))
  if body != nil:
    body_601361 = body
  result = call_601359.call(nil, query_601360, nil, nil, body_601361)

var describeEvents* = Call_DescribeEvents_601344(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEvents",
    validator: validate_DescribeEvents_601345, base: "/", url: url_DescribeEvents_601346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrderableReplicationInstances_601362 = ref object of OpenApiRestCall_600437
proc url_DescribeOrderableReplicationInstances_601364(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOrderableReplicationInstances_601363(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the replication instance types that can be created in the specified region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601365 = query.getOrDefault("MaxRecords")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "MaxRecords", valid_601365
  var valid_601366 = query.getOrDefault("Marker")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "Marker", valid_601366
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
      "AmazonDMSv20160101.DescribeOrderableReplicationInstances"))
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

proc call*(call_601376: Call_DescribeOrderableReplicationInstances_601362;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication instance types that can be created in the specified region.
  ## 
  let valid = call_601376.validator(path, query, header, formData, body)
  let scheme = call_601376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601376.url(scheme.get, call_601376.host, call_601376.base,
                         call_601376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601376, url, valid)

proc call*(call_601377: Call_DescribeOrderableReplicationInstances_601362;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeOrderableReplicationInstances
  ## Returns information about the replication instance types that can be created in the specified region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601378 = newJObject()
  var body_601379 = newJObject()
  add(query_601378, "MaxRecords", newJString(MaxRecords))
  add(query_601378, "Marker", newJString(Marker))
  if body != nil:
    body_601379 = body
  result = call_601377.call(nil, query_601378, nil, nil, body_601379)

var describeOrderableReplicationInstances* = Call_DescribeOrderableReplicationInstances_601362(
    name: "describeOrderableReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances",
    validator: validate_DescribeOrderableReplicationInstances_601363, base: "/",
    url: url_DescribeOrderableReplicationInstances_601364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingMaintenanceActions_601380 = ref object of OpenApiRestCall_600437
proc url_DescribePendingMaintenanceActions_601382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePendingMaintenanceActions_601381(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## For internal use only
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601383 = query.getOrDefault("MaxRecords")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "MaxRecords", valid_601383
  var valid_601384 = query.getOrDefault("Marker")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "Marker", valid_601384
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
  var valid_601385 = header.getOrDefault("X-Amz-Date")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Date", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Security-Token")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Security-Token", valid_601386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601387 = header.getOrDefault("X-Amz-Target")
  valid_601387 = validateParameter(valid_601387, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribePendingMaintenanceActions"))
  if valid_601387 != nil:
    section.add "X-Amz-Target", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Content-Sha256", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Algorithm")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Algorithm", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Signature")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Signature", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-SignedHeaders", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Credential")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Credential", valid_601392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601394: Call_DescribePendingMaintenanceActions_601380;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For internal use only
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601394, url, valid)

proc call*(call_601395: Call_DescribePendingMaintenanceActions_601380;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describePendingMaintenanceActions
  ## For internal use only
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601396 = newJObject()
  var body_601397 = newJObject()
  add(query_601396, "MaxRecords", newJString(MaxRecords))
  add(query_601396, "Marker", newJString(Marker))
  if body != nil:
    body_601397 = body
  result = call_601395.call(nil, query_601396, nil, nil, body_601397)

var describePendingMaintenanceActions* = Call_DescribePendingMaintenanceActions_601380(
    name: "describePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions",
    validator: validate_DescribePendingMaintenanceActions_601381, base: "/",
    url: url_DescribePendingMaintenanceActions_601382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRefreshSchemasStatus_601398 = ref object of OpenApiRestCall_600437
proc url_DescribeRefreshSchemasStatus_601400(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRefreshSchemasStatus_601399(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601401 = header.getOrDefault("X-Amz-Date")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Date", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Security-Token")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Security-Token", valid_601402
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601403 = header.getOrDefault("X-Amz-Target")
  valid_601403 = validateParameter(valid_601403, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeRefreshSchemasStatus"))
  if valid_601403 != nil:
    section.add "X-Amz-Target", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Content-Sha256", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Algorithm")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Algorithm", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Signature")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Signature", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-SignedHeaders", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Credential")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Credential", valid_601408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601410: Call_DescribeRefreshSchemasStatus_601398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of the RefreshSchemas operation.
  ## 
  let valid = call_601410.validator(path, query, header, formData, body)
  let scheme = call_601410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601410.url(scheme.get, call_601410.host, call_601410.base,
                         call_601410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601410, url, valid)

proc call*(call_601411: Call_DescribeRefreshSchemasStatus_601398; body: JsonNode): Recallable =
  ## describeRefreshSchemasStatus
  ## Returns the status of the RefreshSchemas operation.
  ##   body: JObject (required)
  var body_601412 = newJObject()
  if body != nil:
    body_601412 = body
  result = call_601411.call(nil, nil, nil, nil, body_601412)

var describeRefreshSchemasStatus* = Call_DescribeRefreshSchemasStatus_601398(
    name: "describeRefreshSchemasStatus", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus",
    validator: validate_DescribeRefreshSchemasStatus_601399, base: "/",
    url: url_DescribeRefreshSchemasStatus_601400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstanceTaskLogs_601413 = ref object of OpenApiRestCall_600437
proc url_DescribeReplicationInstanceTaskLogs_601415(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReplicationInstanceTaskLogs_601414(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the task logs for the specified task.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601416 = query.getOrDefault("MaxRecords")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "MaxRecords", valid_601416
  var valid_601417 = query.getOrDefault("Marker")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "Marker", valid_601417
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
  var valid_601418 = header.getOrDefault("X-Amz-Date")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Date", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Security-Token")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Security-Token", valid_601419
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601420 = header.getOrDefault("X-Amz-Target")
  valid_601420 = validateParameter(valid_601420, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"))
  if valid_601420 != nil:
    section.add "X-Amz-Target", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Content-Sha256", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Algorithm")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Algorithm", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Signature")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Signature", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-SignedHeaders", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Credential")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Credential", valid_601425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601427: Call_DescribeReplicationInstanceTaskLogs_601413;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the task logs for the specified task.
  ## 
  let valid = call_601427.validator(path, query, header, formData, body)
  let scheme = call_601427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601427.url(scheme.get, call_601427.host, call_601427.base,
                         call_601427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601427, url, valid)

proc call*(call_601428: Call_DescribeReplicationInstanceTaskLogs_601413;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstanceTaskLogs
  ## Returns information about the task logs for the specified task.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601429 = newJObject()
  var body_601430 = newJObject()
  add(query_601429, "MaxRecords", newJString(MaxRecords))
  add(query_601429, "Marker", newJString(Marker))
  if body != nil:
    body_601430 = body
  result = call_601428.call(nil, query_601429, nil, nil, body_601430)

var describeReplicationInstanceTaskLogs* = Call_DescribeReplicationInstanceTaskLogs_601413(
    name: "describeReplicationInstanceTaskLogs", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs",
    validator: validate_DescribeReplicationInstanceTaskLogs_601414, base: "/",
    url: url_DescribeReplicationInstanceTaskLogs_601415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstances_601431 = ref object of OpenApiRestCall_600437
proc url_DescribeReplicationInstances_601433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReplicationInstances_601432(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about replication instances for your account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601434 = query.getOrDefault("MaxRecords")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "MaxRecords", valid_601434
  var valid_601435 = query.getOrDefault("Marker")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "Marker", valid_601435
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
  var valid_601436 = header.getOrDefault("X-Amz-Date")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Date", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Security-Token")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Security-Token", valid_601437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601438 = header.getOrDefault("X-Amz-Target")
  valid_601438 = validateParameter(valid_601438, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstances"))
  if valid_601438 != nil:
    section.add "X-Amz-Target", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Content-Sha256", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Algorithm")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Algorithm", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Signature")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Signature", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-SignedHeaders", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Credential")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Credential", valid_601443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601445: Call_DescribeReplicationInstances_601431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication instances for your account in the current region.
  ## 
  let valid = call_601445.validator(path, query, header, formData, body)
  let scheme = call_601445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601445.url(scheme.get, call_601445.host, call_601445.base,
                         call_601445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601445, url, valid)

proc call*(call_601446: Call_DescribeReplicationInstances_601431; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstances
  ## Returns information about replication instances for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601447 = newJObject()
  var body_601448 = newJObject()
  add(query_601447, "MaxRecords", newJString(MaxRecords))
  add(query_601447, "Marker", newJString(Marker))
  if body != nil:
    body_601448 = body
  result = call_601446.call(nil, query_601447, nil, nil, body_601448)

var describeReplicationInstances* = Call_DescribeReplicationInstances_601431(
    name: "describeReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances",
    validator: validate_DescribeReplicationInstances_601432, base: "/",
    url: url_DescribeReplicationInstances_601433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationSubnetGroups_601449 = ref object of OpenApiRestCall_600437
proc url_DescribeReplicationSubnetGroups_601451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReplicationSubnetGroups_601450(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the replication subnet groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601452 = query.getOrDefault("MaxRecords")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "MaxRecords", valid_601452
  var valid_601453 = query.getOrDefault("Marker")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "Marker", valid_601453
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
  var valid_601454 = header.getOrDefault("X-Amz-Date")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Date", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Security-Token")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Security-Token", valid_601455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601456 = header.getOrDefault("X-Amz-Target")
  valid_601456 = validateParameter(valid_601456, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationSubnetGroups"))
  if valid_601456 != nil:
    section.add "X-Amz-Target", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Content-Sha256", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Algorithm")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Algorithm", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Signature")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Signature", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-SignedHeaders", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Credential")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Credential", valid_601461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601463: Call_DescribeReplicationSubnetGroups_601449;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication subnet groups.
  ## 
  let valid = call_601463.validator(path, query, header, formData, body)
  let scheme = call_601463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601463.url(scheme.get, call_601463.host, call_601463.base,
                         call_601463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601463, url, valid)

proc call*(call_601464: Call_DescribeReplicationSubnetGroups_601449;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationSubnetGroups
  ## Returns information about the replication subnet groups.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601465 = newJObject()
  var body_601466 = newJObject()
  add(query_601465, "MaxRecords", newJString(MaxRecords))
  add(query_601465, "Marker", newJString(Marker))
  if body != nil:
    body_601466 = body
  result = call_601464.call(nil, query_601465, nil, nil, body_601466)

var describeReplicationSubnetGroups* = Call_DescribeReplicationSubnetGroups_601449(
    name: "describeReplicationSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups",
    validator: validate_DescribeReplicationSubnetGroups_601450, base: "/",
    url: url_DescribeReplicationSubnetGroups_601451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTaskAssessmentResults_601467 = ref object of OpenApiRestCall_600437
proc url_DescribeReplicationTaskAssessmentResults_601469(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReplicationTaskAssessmentResults_601468(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601470 = query.getOrDefault("MaxRecords")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "MaxRecords", valid_601470
  var valid_601471 = query.getOrDefault("Marker")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "Marker", valid_601471
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
  var valid_601472 = header.getOrDefault("X-Amz-Date")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Date", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Security-Token")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Security-Token", valid_601473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601474 = header.getOrDefault("X-Amz-Target")
  valid_601474 = validateParameter(valid_601474, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"))
  if valid_601474 != nil:
    section.add "X-Amz-Target", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Content-Sha256", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Algorithm")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Algorithm", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Signature")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Signature", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-SignedHeaders", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Credential")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Credential", valid_601479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601481: Call_DescribeReplicationTaskAssessmentResults_601467;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ## 
  let valid = call_601481.validator(path, query, header, formData, body)
  let scheme = call_601481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601481.url(scheme.get, call_601481.host, call_601481.base,
                         call_601481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601481, url, valid)

proc call*(call_601482: Call_DescribeReplicationTaskAssessmentResults_601467;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTaskAssessmentResults
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601483 = newJObject()
  var body_601484 = newJObject()
  add(query_601483, "MaxRecords", newJString(MaxRecords))
  add(query_601483, "Marker", newJString(Marker))
  if body != nil:
    body_601484 = body
  result = call_601482.call(nil, query_601483, nil, nil, body_601484)

var describeReplicationTaskAssessmentResults* = Call_DescribeReplicationTaskAssessmentResults_601467(
    name: "describeReplicationTaskAssessmentResults", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults",
    validator: validate_DescribeReplicationTaskAssessmentResults_601468,
    base: "/", url: url_DescribeReplicationTaskAssessmentResults_601469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTasks_601485 = ref object of OpenApiRestCall_600437
proc url_DescribeReplicationTasks_601487(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeReplicationTasks_601486(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about replication tasks for your account in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601488 = query.getOrDefault("MaxRecords")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "MaxRecords", valid_601488
  var valid_601489 = query.getOrDefault("Marker")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "Marker", valid_601489
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
  var valid_601490 = header.getOrDefault("X-Amz-Date")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Date", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Security-Token")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Security-Token", valid_601491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601492 = header.getOrDefault("X-Amz-Target")
  valid_601492 = validateParameter(valid_601492, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTasks"))
  if valid_601492 != nil:
    section.add "X-Amz-Target", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Content-Sha256", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Algorithm")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Algorithm", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Signature")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Signature", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-SignedHeaders", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Credential")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Credential", valid_601497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601499: Call_DescribeReplicationTasks_601485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication tasks for your account in the current region.
  ## 
  let valid = call_601499.validator(path, query, header, formData, body)
  let scheme = call_601499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601499.url(scheme.get, call_601499.host, call_601499.base,
                         call_601499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601499, url, valid)

proc call*(call_601500: Call_DescribeReplicationTasks_601485; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTasks
  ## Returns information about replication tasks for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601501 = newJObject()
  var body_601502 = newJObject()
  add(query_601501, "MaxRecords", newJString(MaxRecords))
  add(query_601501, "Marker", newJString(Marker))
  if body != nil:
    body_601502 = body
  result = call_601500.call(nil, query_601501, nil, nil, body_601502)

var describeReplicationTasks* = Call_DescribeReplicationTasks_601485(
    name: "describeReplicationTasks", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks",
    validator: validate_DescribeReplicationTasks_601486, base: "/",
    url: url_DescribeReplicationTasks_601487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchemas_601503 = ref object of OpenApiRestCall_600437
proc url_DescribeSchemas_601505(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSchemas_601504(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601506 = query.getOrDefault("MaxRecords")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "MaxRecords", valid_601506
  var valid_601507 = query.getOrDefault("Marker")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "Marker", valid_601507
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
  var valid_601508 = header.getOrDefault("X-Amz-Date")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Date", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Security-Token")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Security-Token", valid_601509
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601510 = header.getOrDefault("X-Amz-Target")
  valid_601510 = validateParameter(valid_601510, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeSchemas"))
  if valid_601510 != nil:
    section.add "X-Amz-Target", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Content-Sha256", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Algorithm")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Algorithm", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Signature")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Signature", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-SignedHeaders", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Credential")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Credential", valid_601515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601517: Call_DescribeSchemas_601503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ## 
  let valid = call_601517.validator(path, query, header, formData, body)
  let scheme = call_601517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601517.url(scheme.get, call_601517.host, call_601517.base,
                         call_601517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601517, url, valid)

proc call*(call_601518: Call_DescribeSchemas_601503; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeSchemas
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601519 = newJObject()
  var body_601520 = newJObject()
  add(query_601519, "MaxRecords", newJString(MaxRecords))
  add(query_601519, "Marker", newJString(Marker))
  if body != nil:
    body_601520 = body
  result = call_601518.call(nil, query_601519, nil, nil, body_601520)

var describeSchemas* = Call_DescribeSchemas_601503(name: "describeSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas",
    validator: validate_DescribeSchemas_601504, base: "/", url: url_DescribeSchemas_601505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTableStatistics_601521 = ref object of OpenApiRestCall_600437
proc url_DescribeTableStatistics_601523(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTableStatistics_601522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JString
  ##             : Pagination limit
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601524 = query.getOrDefault("MaxRecords")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "MaxRecords", valid_601524
  var valid_601525 = query.getOrDefault("Marker")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "Marker", valid_601525
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
  var valid_601526 = header.getOrDefault("X-Amz-Date")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Date", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Security-Token")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Security-Token", valid_601527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601528 = header.getOrDefault("X-Amz-Target")
  valid_601528 = validateParameter(valid_601528, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeTableStatistics"))
  if valid_601528 != nil:
    section.add "X-Amz-Target", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Content-Sha256", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Algorithm")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Algorithm", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Signature")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Signature", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-SignedHeaders", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Credential")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Credential", valid_601533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601535: Call_DescribeTableStatistics_601521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ## 
  let valid = call_601535.validator(path, query, header, formData, body)
  let scheme = call_601535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601535.url(scheme.get, call_601535.host, call_601535.base,
                         call_601535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601535, url, valid)

proc call*(call_601536: Call_DescribeTableStatistics_601521; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeTableStatistics
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601537 = newJObject()
  var body_601538 = newJObject()
  add(query_601537, "MaxRecords", newJString(MaxRecords))
  add(query_601537, "Marker", newJString(Marker))
  if body != nil:
    body_601538 = body
  result = call_601536.call(nil, query_601537, nil, nil, body_601538)

var describeTableStatistics* = Call_DescribeTableStatistics_601521(
    name: "describeTableStatistics", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics",
    validator: validate_DescribeTableStatistics_601522, base: "/",
    url: url_DescribeTableStatistics_601523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificate_601539 = ref object of OpenApiRestCall_600437
proc url_ImportCertificate_601541(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ImportCertificate_601540(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601542 = header.getOrDefault("X-Amz-Date")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Date", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Security-Token")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Security-Token", valid_601543
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601544 = header.getOrDefault("X-Amz-Target")
  valid_601544 = validateParameter(valid_601544, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ImportCertificate"))
  if valid_601544 != nil:
    section.add "X-Amz-Target", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Content-Sha256", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Algorithm")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Algorithm", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Signature")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Signature", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-SignedHeaders", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Credential")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Credential", valid_601549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601551: Call_ImportCertificate_601539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads the specified certificate.
  ## 
  let valid = call_601551.validator(path, query, header, formData, body)
  let scheme = call_601551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601551.url(scheme.get, call_601551.host, call_601551.base,
                         call_601551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601551, url, valid)

proc call*(call_601552: Call_ImportCertificate_601539; body: JsonNode): Recallable =
  ## importCertificate
  ## Uploads the specified certificate.
  ##   body: JObject (required)
  var body_601553 = newJObject()
  if body != nil:
    body_601553 = body
  result = call_601552.call(nil, nil, nil, nil, body_601553)

var importCertificate* = Call_ImportCertificate_601539(name: "importCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ImportCertificate",
    validator: validate_ImportCertificate_601540, base: "/",
    url: url_ImportCertificate_601541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601554 = ref object of OpenApiRestCall_600437
proc url_ListTagsForResource_601556(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_601555(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601557 = header.getOrDefault("X-Amz-Date")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Date", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Security-Token")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Security-Token", valid_601558
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601559 = header.getOrDefault("X-Amz-Target")
  valid_601559 = validateParameter(valid_601559, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ListTagsForResource"))
  if valid_601559 != nil:
    section.add "X-Amz-Target", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Content-Sha256", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Algorithm")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Algorithm", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Signature")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Signature", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-SignedHeaders", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Credential")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Credential", valid_601564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601566: Call_ListTagsForResource_601554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for an AWS DMS resource.
  ## 
  let valid = call_601566.validator(path, query, header, formData, body)
  let scheme = call_601566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601566.url(scheme.get, call_601566.host, call_601566.base,
                         call_601566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601566, url, valid)

proc call*(call_601567: Call_ListTagsForResource_601554; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags for an AWS DMS resource.
  ##   body: JObject (required)
  var body_601568 = newJObject()
  if body != nil:
    body_601568 = body
  result = call_601567.call(nil, nil, nil, nil, body_601568)

var listTagsForResource* = Call_ListTagsForResource_601554(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource",
    validator: validate_ListTagsForResource_601555, base: "/",
    url: url_ListTagsForResource_601556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEndpoint_601569 = ref object of OpenApiRestCall_600437
proc url_ModifyEndpoint_601571(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyEndpoint_601570(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601572 = header.getOrDefault("X-Amz-Date")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Date", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Security-Token")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Security-Token", valid_601573
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601574 = header.getOrDefault("X-Amz-Target")
  valid_601574 = validateParameter(valid_601574, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEndpoint"))
  if valid_601574 != nil:
    section.add "X-Amz-Target", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Content-Sha256", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Algorithm")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Algorithm", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Signature")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Signature", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-SignedHeaders", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Credential")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Credential", valid_601579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601581: Call_ModifyEndpoint_601569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified endpoint.
  ## 
  let valid = call_601581.validator(path, query, header, formData, body)
  let scheme = call_601581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601581.url(scheme.get, call_601581.host, call_601581.base,
                         call_601581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601581, url, valid)

proc call*(call_601582: Call_ModifyEndpoint_601569; body: JsonNode): Recallable =
  ## modifyEndpoint
  ## Modifies the specified endpoint.
  ##   body: JObject (required)
  var body_601583 = newJObject()
  if body != nil:
    body_601583 = body
  result = call_601582.call(nil, nil, nil, nil, body_601583)

var modifyEndpoint* = Call_ModifyEndpoint_601569(name: "modifyEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint",
    validator: validate_ModifyEndpoint_601570, base: "/", url: url_ModifyEndpoint_601571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEventSubscription_601584 = ref object of OpenApiRestCall_600437
proc url_ModifyEventSubscription_601586(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyEventSubscription_601585(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601587 = header.getOrDefault("X-Amz-Date")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Date", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Security-Token")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Security-Token", valid_601588
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601589 = header.getOrDefault("X-Amz-Target")
  valid_601589 = validateParameter(valid_601589, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEventSubscription"))
  if valid_601589 != nil:
    section.add "X-Amz-Target", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Content-Sha256", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Algorithm")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Algorithm", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Signature")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Signature", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-SignedHeaders", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Credential")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Credential", valid_601594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601596: Call_ModifyEventSubscription_601584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing AWS DMS event notification subscription. 
  ## 
  let valid = call_601596.validator(path, query, header, formData, body)
  let scheme = call_601596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601596.url(scheme.get, call_601596.host, call_601596.base,
                         call_601596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601596, url, valid)

proc call*(call_601597: Call_ModifyEventSubscription_601584; body: JsonNode): Recallable =
  ## modifyEventSubscription
  ## Modifies an existing AWS DMS event notification subscription. 
  ##   body: JObject (required)
  var body_601598 = newJObject()
  if body != nil:
    body_601598 = body
  result = call_601597.call(nil, nil, nil, nil, body_601598)

var modifyEventSubscription* = Call_ModifyEventSubscription_601584(
    name: "modifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription",
    validator: validate_ModifyEventSubscription_601585, base: "/",
    url: url_ModifyEventSubscription_601586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationInstance_601599 = ref object of OpenApiRestCall_600437
proc url_ModifyReplicationInstance_601601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyReplicationInstance_601600(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601602 = header.getOrDefault("X-Amz-Date")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Date", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Security-Token")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Security-Token", valid_601603
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601604 = header.getOrDefault("X-Amz-Target")
  valid_601604 = validateParameter(valid_601604, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationInstance"))
  if valid_601604 != nil:
    section.add "X-Amz-Target", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Content-Sha256", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Algorithm")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Algorithm", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Signature")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Signature", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-SignedHeaders", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Credential")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Credential", valid_601609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601611: Call_ModifyReplicationInstance_601599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ## 
  let valid = call_601611.validator(path, query, header, formData, body)
  let scheme = call_601611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601611.url(scheme.get, call_601611.host, call_601611.base,
                         call_601611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601611, url, valid)

proc call*(call_601612: Call_ModifyReplicationInstance_601599; body: JsonNode): Recallable =
  ## modifyReplicationInstance
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ##   body: JObject (required)
  var body_601613 = newJObject()
  if body != nil:
    body_601613 = body
  result = call_601612.call(nil, nil, nil, nil, body_601613)

var modifyReplicationInstance* = Call_ModifyReplicationInstance_601599(
    name: "modifyReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance",
    validator: validate_ModifyReplicationInstance_601600, base: "/",
    url: url_ModifyReplicationInstance_601601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationSubnetGroup_601614 = ref object of OpenApiRestCall_600437
proc url_ModifyReplicationSubnetGroup_601616(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyReplicationSubnetGroup_601615(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601617 = header.getOrDefault("X-Amz-Date")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Date", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Security-Token")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Security-Token", valid_601618
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601619 = header.getOrDefault("X-Amz-Target")
  valid_601619 = validateParameter(valid_601619, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationSubnetGroup"))
  if valid_601619 != nil:
    section.add "X-Amz-Target", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Content-Sha256", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Algorithm")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Algorithm", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Signature")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Signature", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-SignedHeaders", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Credential")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Credential", valid_601624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601626: Call_ModifyReplicationSubnetGroup_601614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for the specified replication subnet group.
  ## 
  let valid = call_601626.validator(path, query, header, formData, body)
  let scheme = call_601626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601626.url(scheme.get, call_601626.host, call_601626.base,
                         call_601626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601626, url, valid)

proc call*(call_601627: Call_ModifyReplicationSubnetGroup_601614; body: JsonNode): Recallable =
  ## modifyReplicationSubnetGroup
  ## Modifies the settings for the specified replication subnet group.
  ##   body: JObject (required)
  var body_601628 = newJObject()
  if body != nil:
    body_601628 = body
  result = call_601627.call(nil, nil, nil, nil, body_601628)

var modifyReplicationSubnetGroup* = Call_ModifyReplicationSubnetGroup_601614(
    name: "modifyReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup",
    validator: validate_ModifyReplicationSubnetGroup_601615, base: "/",
    url: url_ModifyReplicationSubnetGroup_601616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationTask_601629 = ref object of OpenApiRestCall_600437
proc url_ModifyReplicationTask_601631(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ModifyReplicationTask_601630(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601632 = header.getOrDefault("X-Amz-Date")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Date", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Security-Token")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Security-Token", valid_601633
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601634 = header.getOrDefault("X-Amz-Target")
  valid_601634 = validateParameter(valid_601634, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationTask"))
  if valid_601634 != nil:
    section.add "X-Amz-Target", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Content-Sha256", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Algorithm")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Algorithm", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Signature")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Signature", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-SignedHeaders", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Credential")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Credential", valid_601639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601641: Call_ModifyReplicationTask_601629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ## 
  let valid = call_601641.validator(path, query, header, formData, body)
  let scheme = call_601641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601641.url(scheme.get, call_601641.host, call_601641.base,
                         call_601641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601641, url, valid)

proc call*(call_601642: Call_ModifyReplicationTask_601629; body: JsonNode): Recallable =
  ## modifyReplicationTask
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ##   body: JObject (required)
  var body_601643 = newJObject()
  if body != nil:
    body_601643 = body
  result = call_601642.call(nil, nil, nil, nil, body_601643)

var modifyReplicationTask* = Call_ModifyReplicationTask_601629(
    name: "modifyReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask",
    validator: validate_ModifyReplicationTask_601630, base: "/",
    url: url_ModifyReplicationTask_601631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootReplicationInstance_601644 = ref object of OpenApiRestCall_600437
proc url_RebootReplicationInstance_601646(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RebootReplicationInstance_601645(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601647 = header.getOrDefault("X-Amz-Date")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Date", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Security-Token")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Security-Token", valid_601648
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601649 = header.getOrDefault("X-Amz-Target")
  valid_601649 = validateParameter(valid_601649, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RebootReplicationInstance"))
  if valid_601649 != nil:
    section.add "X-Amz-Target", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Content-Sha256", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Algorithm")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Algorithm", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Signature")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Signature", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-SignedHeaders", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Credential")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Credential", valid_601654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601656: Call_RebootReplicationInstance_601644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ## 
  let valid = call_601656.validator(path, query, header, formData, body)
  let scheme = call_601656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601656.url(scheme.get, call_601656.host, call_601656.base,
                         call_601656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601656, url, valid)

proc call*(call_601657: Call_RebootReplicationInstance_601644; body: JsonNode): Recallable =
  ## rebootReplicationInstance
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ##   body: JObject (required)
  var body_601658 = newJObject()
  if body != nil:
    body_601658 = body
  result = call_601657.call(nil, nil, nil, nil, body_601658)

var rebootReplicationInstance* = Call_RebootReplicationInstance_601644(
    name: "rebootReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance",
    validator: validate_RebootReplicationInstance_601645, base: "/",
    url: url_RebootReplicationInstance_601646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshSchemas_601659 = ref object of OpenApiRestCall_600437
proc url_RefreshSchemas_601661(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RefreshSchemas_601660(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601662 = header.getOrDefault("X-Amz-Date")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Date", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Security-Token")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Security-Token", valid_601663
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601664 = header.getOrDefault("X-Amz-Target")
  valid_601664 = validateParameter(valid_601664, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RefreshSchemas"))
  if valid_601664 != nil:
    section.add "X-Amz-Target", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Content-Sha256", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Algorithm")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Algorithm", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Signature")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Signature", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-SignedHeaders", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Credential")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Credential", valid_601669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601671: Call_RefreshSchemas_601659; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ## 
  let valid = call_601671.validator(path, query, header, formData, body)
  let scheme = call_601671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601671.url(scheme.get, call_601671.host, call_601671.base,
                         call_601671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601671, url, valid)

proc call*(call_601672: Call_RefreshSchemas_601659; body: JsonNode): Recallable =
  ## refreshSchemas
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ##   body: JObject (required)
  var body_601673 = newJObject()
  if body != nil:
    body_601673 = body
  result = call_601672.call(nil, nil, nil, nil, body_601673)

var refreshSchemas* = Call_RefreshSchemas_601659(name: "refreshSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas",
    validator: validate_RefreshSchemas_601660, base: "/", url: url_RefreshSchemas_601661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReloadTables_601674 = ref object of OpenApiRestCall_600437
proc url_ReloadTables_601676(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ReloadTables_601675(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601677 = header.getOrDefault("X-Amz-Date")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Date", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Security-Token")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Security-Token", valid_601678
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601679 = header.getOrDefault("X-Amz-Target")
  valid_601679 = validateParameter(valid_601679, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ReloadTables"))
  if valid_601679 != nil:
    section.add "X-Amz-Target", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Content-Sha256", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Algorithm")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Algorithm", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Signature")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Signature", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-SignedHeaders", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Credential")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Credential", valid_601684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601686: Call_ReloadTables_601674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reloads the target database table with the source data. 
  ## 
  let valid = call_601686.validator(path, query, header, formData, body)
  let scheme = call_601686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601686.url(scheme.get, call_601686.host, call_601686.base,
                         call_601686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601686, url, valid)

proc call*(call_601687: Call_ReloadTables_601674; body: JsonNode): Recallable =
  ## reloadTables
  ## Reloads the target database table with the source data. 
  ##   body: JObject (required)
  var body_601688 = newJObject()
  if body != nil:
    body_601688 = body
  result = call_601687.call(nil, nil, nil, nil, body_601688)

var reloadTables* = Call_ReloadTables_601674(name: "reloadTables",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ReloadTables",
    validator: validate_ReloadTables_601675, base: "/", url: url_ReloadTables_601676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_601689 = ref object of OpenApiRestCall_600437
proc url_RemoveTagsFromResource_601691(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RemoveTagsFromResource_601690(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601692 = header.getOrDefault("X-Amz-Date")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Date", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Security-Token")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Security-Token", valid_601693
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601694 = header.getOrDefault("X-Amz-Target")
  valid_601694 = validateParameter(valid_601694, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RemoveTagsFromResource"))
  if valid_601694 != nil:
    section.add "X-Amz-Target", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Content-Sha256", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Algorithm")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Algorithm", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Signature")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Signature", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-SignedHeaders", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Credential")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Credential", valid_601699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601701: Call_RemoveTagsFromResource_601689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a DMS resource.
  ## 
  let valid = call_601701.validator(path, query, header, formData, body)
  let scheme = call_601701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601701.url(scheme.get, call_601701.host, call_601701.base,
                         call_601701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601701, url, valid)

proc call*(call_601702: Call_RemoveTagsFromResource_601689; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes metadata tags from a DMS resource.
  ##   body: JObject (required)
  var body_601703 = newJObject()
  if body != nil:
    body_601703 = body
  result = call_601702.call(nil, nil, nil, nil, body_601703)

var removeTagsFromResource* = Call_RemoveTagsFromResource_601689(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_601690, base: "/",
    url: url_RemoveTagsFromResource_601691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTask_601704 = ref object of OpenApiRestCall_600437
proc url_StartReplicationTask_601706(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartReplicationTask_601705(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601707 = header.getOrDefault("X-Amz-Date")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Date", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Security-Token")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Security-Token", valid_601708
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601709 = header.getOrDefault("X-Amz-Target")
  valid_601709 = validateParameter(valid_601709, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTask"))
  if valid_601709 != nil:
    section.add "X-Amz-Target", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Content-Sha256", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Algorithm")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Algorithm", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Signature")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Signature", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-SignedHeaders", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Credential")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Credential", valid_601714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601716: Call_StartReplicationTask_601704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_601716.validator(path, query, header, formData, body)
  let scheme = call_601716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601716.url(scheme.get, call_601716.host, call_601716.base,
                         call_601716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601716, url, valid)

proc call*(call_601717: Call_StartReplicationTask_601704; body: JsonNode): Recallable =
  ## startReplicationTask
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_601718 = newJObject()
  if body != nil:
    body_601718 = body
  result = call_601717.call(nil, nil, nil, nil, body_601718)

var startReplicationTask* = Call_StartReplicationTask_601704(
    name: "startReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask",
    validator: validate_StartReplicationTask_601705, base: "/",
    url: url_StartReplicationTask_601706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTaskAssessment_601719 = ref object of OpenApiRestCall_600437
proc url_StartReplicationTaskAssessment_601721(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartReplicationTaskAssessment_601720(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601722 = header.getOrDefault("X-Amz-Date")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Date", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Security-Token")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Security-Token", valid_601723
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601724 = header.getOrDefault("X-Amz-Target")
  valid_601724 = validateParameter(valid_601724, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTaskAssessment"))
  if valid_601724 != nil:
    section.add "X-Amz-Target", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Content-Sha256", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Algorithm")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Algorithm", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Signature")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Signature", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-SignedHeaders", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Credential")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Credential", valid_601729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601731: Call_StartReplicationTaskAssessment_601719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ## 
  let valid = call_601731.validator(path, query, header, formData, body)
  let scheme = call_601731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601731.url(scheme.get, call_601731.host, call_601731.base,
                         call_601731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601731, url, valid)

proc call*(call_601732: Call_StartReplicationTaskAssessment_601719; body: JsonNode): Recallable =
  ## startReplicationTaskAssessment
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ##   body: JObject (required)
  var body_601733 = newJObject()
  if body != nil:
    body_601733 = body
  result = call_601732.call(nil, nil, nil, nil, body_601733)

var startReplicationTaskAssessment* = Call_StartReplicationTaskAssessment_601719(
    name: "startReplicationTaskAssessment", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment",
    validator: validate_StartReplicationTaskAssessment_601720, base: "/",
    url: url_StartReplicationTaskAssessment_601721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopReplicationTask_601734 = ref object of OpenApiRestCall_600437
proc url_StopReplicationTask_601736(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopReplicationTask_601735(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601737 = header.getOrDefault("X-Amz-Date")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Date", valid_601737
  var valid_601738 = header.getOrDefault("X-Amz-Security-Token")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-Security-Token", valid_601738
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601739 = header.getOrDefault("X-Amz-Target")
  valid_601739 = validateParameter(valid_601739, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StopReplicationTask"))
  if valid_601739 != nil:
    section.add "X-Amz-Target", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Content-Sha256", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Algorithm")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Algorithm", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Signature")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Signature", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-SignedHeaders", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Credential")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Credential", valid_601744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601746: Call_StopReplicationTask_601734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops the replication task.</p> <p/>
  ## 
  let valid = call_601746.validator(path, query, header, formData, body)
  let scheme = call_601746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601746.url(scheme.get, call_601746.host, call_601746.base,
                         call_601746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601746, url, valid)

proc call*(call_601747: Call_StopReplicationTask_601734; body: JsonNode): Recallable =
  ## stopReplicationTask
  ## <p>Stops the replication task.</p> <p/>
  ##   body: JObject (required)
  var body_601748 = newJObject()
  if body != nil:
    body_601748 = body
  result = call_601747.call(nil, nil, nil, nil, body_601748)

var stopReplicationTask* = Call_StopReplicationTask_601734(
    name: "stopReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask",
    validator: validate_StopReplicationTask_601735, base: "/",
    url: url_StopReplicationTask_601736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestConnection_601749 = ref object of OpenApiRestCall_600437
proc url_TestConnection_601751(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestConnection_601750(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601752 = header.getOrDefault("X-Amz-Date")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Date", valid_601752
  var valid_601753 = header.getOrDefault("X-Amz-Security-Token")
  valid_601753 = validateParameter(valid_601753, JString, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "X-Amz-Security-Token", valid_601753
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601754 = header.getOrDefault("X-Amz-Target")
  valid_601754 = validateParameter(valid_601754, JString, required = true, default = newJString(
      "AmazonDMSv20160101.TestConnection"))
  if valid_601754 != nil:
    section.add "X-Amz-Target", valid_601754
  var valid_601755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-Content-Sha256", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-Algorithm")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Algorithm", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-Signature")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Signature", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-SignedHeaders", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Credential")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Credential", valid_601759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601761: Call_TestConnection_601749; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the connection between the replication instance and the endpoint.
  ## 
  let valid = call_601761.validator(path, query, header, formData, body)
  let scheme = call_601761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601761.url(scheme.get, call_601761.host, call_601761.base,
                         call_601761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601761, url, valid)

proc call*(call_601762: Call_TestConnection_601749; body: JsonNode): Recallable =
  ## testConnection
  ## Tests the connection between the replication instance and the endpoint.
  ##   body: JObject (required)
  var body_601763 = newJObject()
  if body != nil:
    body_601763 = body
  result = call_601762.call(nil, nil, nil, nil, body_601763)

var testConnection* = Call_TestConnection_601749(name: "testConnection",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.TestConnection",
    validator: validate_TestConnection_601750, base: "/", url: url_TestConnection_601751,
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
