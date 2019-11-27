
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AddTagsToResource_599705 = ref object of OpenApiRestCall_599368
proc url_AddTagsToResource_599707(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToResource_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "AmazonDMSv20160101.AddTagsToResource"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AddTagsToResource_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AddTagsToResource_599705; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var addTagsToResource* = Call_AddTagsToResource_599705(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource",
    validator: validate_AddTagsToResource_599706, base: "/",
    url: url_AddTagsToResource_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplyPendingMaintenanceAction_599974 = ref object of OpenApiRestCall_599368
proc url_ApplyPendingMaintenanceAction_599976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ApplyPendingMaintenanceAction_599975(path: JsonNode; query: JsonNode;
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ApplyPendingMaintenanceAction"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_ApplyPendingMaintenanceAction_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_ApplyPendingMaintenanceAction_599974; body: JsonNode): Recallable =
  ## applyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var applyPendingMaintenanceAction* = Call_ApplyPendingMaintenanceAction_599974(
    name: "applyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction",
    validator: validate_ApplyPendingMaintenanceAction_599975, base: "/",
    url: url_ApplyPendingMaintenanceAction_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_599989 = ref object of OpenApiRestCall_599368
proc url_CreateEndpoint_599991(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_599990(path: JsonNode; query: JsonNode;
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEndpoint"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_CreateEndpoint_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint using the provided settings.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_CreateEndpoint_599989; body: JsonNode): Recallable =
  ## createEndpoint
  ## Creates an endpoint using the provided settings.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var createEndpoint* = Call_CreateEndpoint_599989(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint",
    validator: validate_CreateEndpoint_599990, base: "/", url: url_CreateEndpoint_599991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSubscription_600004 = ref object of OpenApiRestCall_599368
proc url_CreateEventSubscription_600006(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEventSubscription_600005(path: JsonNode; query: JsonNode;
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEventSubscription"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_CreateEventSubscription_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_CreateEventSubscription_600004; body: JsonNode): Recallable =
  ## createEventSubscription
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var createEventSubscription* = Call_CreateEventSubscription_600004(
    name: "createEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription",
    validator: validate_CreateEventSubscription_600005, base: "/",
    url: url_CreateEventSubscription_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationInstance_600019 = ref object of OpenApiRestCall_599368
proc url_CreateReplicationInstance_600021(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReplicationInstance_600020(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationInstance"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_CreateReplicationInstance_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates the replication instance using the specified parameters.</p> <p>AWS DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.APIRole.html">Creating the IAM Roles to Use With the AWS CLI and AWS DMS API</a>. For information on the required permissions, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.IAMPermissions.html">IAM Permissions Needed to Use AWS DMS</a>.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_CreateReplicationInstance_600019; body: JsonNode): Recallable =
  ## createReplicationInstance
  ## <p>Creates the replication instance using the specified parameters.</p> <p>AWS DMS requires that your account have certain roles with appropriate permissions before you can create a replication instance. For information on the required roles, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.APIRole.html">Creating the IAM Roles to Use With the AWS CLI and AWS DMS API</a>. For information on the required permissions, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.IAMPermissions.html">IAM Permissions Needed to Use AWS DMS</a>.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var createReplicationInstance* = Call_CreateReplicationInstance_600019(
    name: "createReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance",
    validator: validate_CreateReplicationInstance_600020, base: "/",
    url: url_CreateReplicationInstance_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationSubnetGroup_600034 = ref object of OpenApiRestCall_599368
proc url_CreateReplicationSubnetGroup_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReplicationSubnetGroup_600035(path: JsonNode; query: JsonNode;
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationSubnetGroup"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_CreateReplicationSubnetGroup_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_CreateReplicationSubnetGroup_600034; body: JsonNode): Recallable =
  ## createReplicationSubnetGroup
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var createReplicationSubnetGroup* = Call_CreateReplicationSubnetGroup_600034(
    name: "createReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup",
    validator: validate_CreateReplicationSubnetGroup_600035, base: "/",
    url: url_CreateReplicationSubnetGroup_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationTask_600049 = ref object of OpenApiRestCall_599368
proc url_CreateReplicationTask_600051(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateReplicationTask_600050(path: JsonNode; query: JsonNode;
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationTask"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_CreateReplicationTask_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication task using the specified parameters.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_CreateReplicationTask_600049; body: JsonNode): Recallable =
  ## createReplicationTask
  ## Creates a replication task using the specified parameters.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var createReplicationTask* = Call_CreateReplicationTask_600049(
    name: "createReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask",
    validator: validate_CreateReplicationTask_600050, base: "/",
    url: url_CreateReplicationTask_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificate_600064 = ref object of OpenApiRestCall_599368
proc url_DeleteCertificate_600066(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCertificate_600065(path: JsonNode; query: JsonNode;
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteCertificate"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_DeleteCertificate_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified certificate. 
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_DeleteCertificate_600064; body: JsonNode): Recallable =
  ## deleteCertificate
  ## Deletes the specified certificate. 
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var deleteCertificate* = Call_DeleteCertificate_600064(name: "deleteCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate",
    validator: validate_DeleteCertificate_600065, base: "/",
    url: url_DeleteCertificate_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_600079 = ref object of OpenApiRestCall_599368
proc url_DeleteConnection_600081(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteConnection_600080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteConnection"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_DeleteConnection_600079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the connection between a replication instance and an endpoint.
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_DeleteConnection_600079; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes the connection between a replication instance and an endpoint.
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var deleteConnection* = Call_DeleteConnection_600079(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteConnection",
    validator: validate_DeleteConnection_600080, base: "/",
    url: url_DeleteConnection_600081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_600094 = ref object of OpenApiRestCall_599368
proc url_DeleteEndpoint_600096(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_600095(path: JsonNode; query: JsonNode;
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEndpoint"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_DeleteEndpoint_600094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_DeleteEndpoint_600094; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var deleteEndpoint* = Call_DeleteEndpoint_600094(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint",
    validator: validate_DeleteEndpoint_600095, base: "/", url: url_DeleteEndpoint_600096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSubscription_600109 = ref object of OpenApiRestCall_599368
proc url_DeleteEventSubscription_600111(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEventSubscription_600110(path: JsonNode; query: JsonNode;
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEventSubscription"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_DeleteEventSubscription_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an AWS DMS event subscription. 
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_DeleteEventSubscription_600109; body: JsonNode): Recallable =
  ## deleteEventSubscription
  ##  Deletes an AWS DMS event subscription. 
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var deleteEventSubscription* = Call_DeleteEventSubscription_600109(
    name: "deleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription",
    validator: validate_DeleteEventSubscription_600110, base: "/",
    url: url_DeleteEventSubscription_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationInstance_600124 = ref object of OpenApiRestCall_599368
proc url_DeleteReplicationInstance_600126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReplicationInstance_600125(path: JsonNode; query: JsonNode;
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationInstance"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_DeleteReplicationInstance_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_DeleteReplicationInstance_600124; body: JsonNode): Recallable =
  ## deleteReplicationInstance
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var deleteReplicationInstance* = Call_DeleteReplicationInstance_600124(
    name: "deleteReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance",
    validator: validate_DeleteReplicationInstance_600125, base: "/",
    url: url_DeleteReplicationInstance_600126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationSubnetGroup_600139 = ref object of OpenApiRestCall_599368
proc url_DeleteReplicationSubnetGroup_600141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReplicationSubnetGroup_600140(path: JsonNode; query: JsonNode;
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationSubnetGroup"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_DeleteReplicationSubnetGroup_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subnet group.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_DeleteReplicationSubnetGroup_600139; body: JsonNode): Recallable =
  ## deleteReplicationSubnetGroup
  ## Deletes a subnet group.
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var deleteReplicationSubnetGroup* = Call_DeleteReplicationSubnetGroup_600139(
    name: "deleteReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup",
    validator: validate_DeleteReplicationSubnetGroup_600140, base: "/",
    url: url_DeleteReplicationSubnetGroup_600141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationTask_600154 = ref object of OpenApiRestCall_599368
proc url_DeleteReplicationTask_600156(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteReplicationTask_600155(path: JsonNode; query: JsonNode;
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationTask"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_DeleteReplicationTask_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified replication task.
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_DeleteReplicationTask_600154; body: JsonNode): Recallable =
  ## deleteReplicationTask
  ## Deletes the specified replication task.
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var deleteReplicationTask* = Call_DeleteReplicationTask_600154(
    name: "deleteReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask",
    validator: validate_DeleteReplicationTask_600155, base: "/",
    url: url_DeleteReplicationTask_600156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_600169 = ref object of OpenApiRestCall_599368
proc url_DescribeAccountAttributes_600171(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAccountAttributes_600170(path: JsonNode; query: JsonNode;
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeAccountAttributes"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_DescribeAccountAttributes_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_DescribeAccountAttributes_600169; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var describeAccountAttributes* = Call_DescribeAccountAttributes_600169(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_600170, base: "/",
    url: url_DescribeAccountAttributes_600171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificates_600184 = ref object of OpenApiRestCall_599368
proc url_DescribeCertificates_600186(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCertificates_600185(path: JsonNode; query: JsonNode;
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
  var valid_600187 = query.getOrDefault("MaxRecords")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "MaxRecords", valid_600187
  var valid_600188 = query.getOrDefault("Marker")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "Marker", valid_600188
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
  var valid_600189 = header.getOrDefault("X-Amz-Date")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Date", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Security-Token")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Security-Token", valid_600190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600191 = header.getOrDefault("X-Amz-Target")
  valid_600191 = validateParameter(valid_600191, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeCertificates"))
  if valid_600191 != nil:
    section.add "X-Amz-Target", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600198: Call_DescribeCertificates_600184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a description of the certificate.
  ## 
  let valid = call_600198.validator(path, query, header, formData, body)
  let scheme = call_600198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600198.url(scheme.get, call_600198.host, call_600198.base,
                         call_600198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600198, url, valid)

proc call*(call_600199: Call_DescribeCertificates_600184; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeCertificates
  ## Provides a description of the certificate.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600200 = newJObject()
  var body_600201 = newJObject()
  add(query_600200, "MaxRecords", newJString(MaxRecords))
  add(query_600200, "Marker", newJString(Marker))
  if body != nil:
    body_600201 = body
  result = call_600199.call(nil, query_600200, nil, nil, body_600201)

var describeCertificates* = Call_DescribeCertificates_600184(
    name: "describeCertificates", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates",
    validator: validate_DescribeCertificates_600185, base: "/",
    url: url_DescribeCertificates_600186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_600203 = ref object of OpenApiRestCall_599368
proc url_DescribeConnections_600205(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConnections_600204(path: JsonNode; query: JsonNode;
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
  var valid_600206 = query.getOrDefault("MaxRecords")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "MaxRecords", valid_600206
  var valid_600207 = query.getOrDefault("Marker")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "Marker", valid_600207
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
  var valid_600208 = header.getOrDefault("X-Amz-Date")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Date", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Security-Token")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Security-Token", valid_600209
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600210 = header.getOrDefault("X-Amz-Target")
  valid_600210 = validateParameter(valid_600210, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeConnections"))
  if valid_600210 != nil:
    section.add "X-Amz-Target", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Content-Sha256", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Algorithm")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Algorithm", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Signature")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Signature", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-SignedHeaders", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Credential")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Credential", valid_600215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600217: Call_DescribeConnections_600203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ## 
  let valid = call_600217.validator(path, query, header, formData, body)
  let scheme = call_600217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600217.url(scheme.get, call_600217.host, call_600217.base,
                         call_600217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600217, url, valid)

proc call*(call_600218: Call_DescribeConnections_600203; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeConnections
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600219 = newJObject()
  var body_600220 = newJObject()
  add(query_600219, "MaxRecords", newJString(MaxRecords))
  add(query_600219, "Marker", newJString(Marker))
  if body != nil:
    body_600220 = body
  result = call_600218.call(nil, query_600219, nil, nil, body_600220)

var describeConnections* = Call_DescribeConnections_600203(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeConnections",
    validator: validate_DescribeConnections_600204, base: "/",
    url: url_DescribeConnections_600205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointTypes_600221 = ref object of OpenApiRestCall_599368
proc url_DescribeEndpointTypes_600223(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpointTypes_600222(path: JsonNode; query: JsonNode;
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
  var valid_600224 = query.getOrDefault("MaxRecords")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "MaxRecords", valid_600224
  var valid_600225 = query.getOrDefault("Marker")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "Marker", valid_600225
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
  var valid_600226 = header.getOrDefault("X-Amz-Date")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Date", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Security-Token")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Security-Token", valid_600227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600228 = header.getOrDefault("X-Amz-Target")
  valid_600228 = validateParameter(valid_600228, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpointTypes"))
  if valid_600228 != nil:
    section.add "X-Amz-Target", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Content-Sha256", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Algorithm")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Algorithm", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Signature")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Signature", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-SignedHeaders", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Credential")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Credential", valid_600233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600235: Call_DescribeEndpointTypes_600221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the type of endpoints available.
  ## 
  let valid = call_600235.validator(path, query, header, formData, body)
  let scheme = call_600235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600235.url(scheme.get, call_600235.host, call_600235.base,
                         call_600235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600235, url, valid)

proc call*(call_600236: Call_DescribeEndpointTypes_600221; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpointTypes
  ## Returns information about the type of endpoints available.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600237 = newJObject()
  var body_600238 = newJObject()
  add(query_600237, "MaxRecords", newJString(MaxRecords))
  add(query_600237, "Marker", newJString(Marker))
  if body != nil:
    body_600238 = body
  result = call_600236.call(nil, query_600237, nil, nil, body_600238)

var describeEndpointTypes* = Call_DescribeEndpointTypes_600221(
    name: "describeEndpointTypes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes",
    validator: validate_DescribeEndpointTypes_600222, base: "/",
    url: url_DescribeEndpointTypes_600223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_600239 = ref object of OpenApiRestCall_599368
proc url_DescribeEndpoints_600241(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoints_600240(path: JsonNode; query: JsonNode;
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
  var valid_600242 = query.getOrDefault("MaxRecords")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "MaxRecords", valid_600242
  var valid_600243 = query.getOrDefault("Marker")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "Marker", valid_600243
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
      "AmazonDMSv20160101.DescribeEndpoints"))
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

proc call*(call_600253: Call_DescribeEndpoints_600239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the endpoints for your account in the current region.
  ## 
  let valid = call_600253.validator(path, query, header, formData, body)
  let scheme = call_600253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600253.url(scheme.get, call_600253.host, call_600253.base,
                         call_600253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600253, url, valid)

proc call*(call_600254: Call_DescribeEndpoints_600239; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpoints
  ## Returns information about the endpoints for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600255 = newJObject()
  var body_600256 = newJObject()
  add(query_600255, "MaxRecords", newJString(MaxRecords))
  add(query_600255, "Marker", newJString(Marker))
  if body != nil:
    body_600256 = body
  result = call_600254.call(nil, query_600255, nil, nil, body_600256)

var describeEndpoints* = Call_DescribeEndpoints_600239(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints",
    validator: validate_DescribeEndpoints_600240, base: "/",
    url: url_DescribeEndpoints_600241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventCategories_600257 = ref object of OpenApiRestCall_599368
proc url_DescribeEventCategories_600259(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventCategories_600258(path: JsonNode; query: JsonNode;
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
  var valid_600260 = header.getOrDefault("X-Amz-Date")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Date", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Security-Token")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Security-Token", valid_600261
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600262 = header.getOrDefault("X-Amz-Target")
  valid_600262 = validateParameter(valid_600262, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventCategories"))
  if valid_600262 != nil:
    section.add "X-Amz-Target", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Content-Sha256", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Algorithm")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Algorithm", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Signature")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Signature", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-SignedHeaders", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Credential")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Credential", valid_600267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_DescribeEventCategories_600257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ## 
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_DescribeEventCategories_600257; body: JsonNode): Recallable =
  ## describeEventCategories
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ##   body: JObject (required)
  var body_600271 = newJObject()
  if body != nil:
    body_600271 = body
  result = call_600270.call(nil, nil, nil, nil, body_600271)

var describeEventCategories* = Call_DescribeEventCategories_600257(
    name: "describeEventCategories", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories",
    validator: validate_DescribeEventCategories_600258, base: "/",
    url: url_DescribeEventCategories_600259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventSubscriptions_600272 = ref object of OpenApiRestCall_599368
proc url_DescribeEventSubscriptions_600274(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEventSubscriptions_600273(path: JsonNode; query: JsonNode;
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
  var valid_600275 = query.getOrDefault("MaxRecords")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "MaxRecords", valid_600275
  var valid_600276 = query.getOrDefault("Marker")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "Marker", valid_600276
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
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600279 = header.getOrDefault("X-Amz-Target")
  valid_600279 = validateParameter(valid_600279, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventSubscriptions"))
  if valid_600279 != nil:
    section.add "X-Amz-Target", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_DescribeEventSubscriptions_600272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_DescribeEventSubscriptions_600272; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEventSubscriptions
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600288 = newJObject()
  var body_600289 = newJObject()
  add(query_600288, "MaxRecords", newJString(MaxRecords))
  add(query_600288, "Marker", newJString(Marker))
  if body != nil:
    body_600289 = body
  result = call_600287.call(nil, query_600288, nil, nil, body_600289)

var describeEventSubscriptions* = Call_DescribeEventSubscriptions_600272(
    name: "describeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions",
    validator: validate_DescribeEventSubscriptions_600273, base: "/",
    url: url_DescribeEventSubscriptions_600274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_600290 = ref object of OpenApiRestCall_599368
proc url_DescribeEvents_600292(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvents_600291(path: JsonNode; query: JsonNode;
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
  var valid_600293 = query.getOrDefault("MaxRecords")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "MaxRecords", valid_600293
  var valid_600294 = query.getOrDefault("Marker")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "Marker", valid_600294
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
  var valid_600295 = header.getOrDefault("X-Amz-Date")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Date", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Security-Token")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Security-Token", valid_600296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600297 = header.getOrDefault("X-Amz-Target")
  valid_600297 = validateParameter(valid_600297, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEvents"))
  if valid_600297 != nil:
    section.add "X-Amz-Target", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Content-Sha256", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Algorithm")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Algorithm", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Signature")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Signature", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-SignedHeaders", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Credential")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Credential", valid_600302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600304: Call_DescribeEvents_600290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ## 
  let valid = call_600304.validator(path, query, header, formData, body)
  let scheme = call_600304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600304.url(scheme.get, call_600304.host, call_600304.base,
                         call_600304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600304, url, valid)

proc call*(call_600305: Call_DescribeEvents_600290; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEvents
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600306 = newJObject()
  var body_600307 = newJObject()
  add(query_600306, "MaxRecords", newJString(MaxRecords))
  add(query_600306, "Marker", newJString(Marker))
  if body != nil:
    body_600307 = body
  result = call_600305.call(nil, query_600306, nil, nil, body_600307)

var describeEvents* = Call_DescribeEvents_600290(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEvents",
    validator: validate_DescribeEvents_600291, base: "/", url: url_DescribeEvents_600292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrderableReplicationInstances_600308 = ref object of OpenApiRestCall_599368
proc url_DescribeOrderableReplicationInstances_600310(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOrderableReplicationInstances_600309(path: JsonNode;
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
  var valid_600311 = query.getOrDefault("MaxRecords")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "MaxRecords", valid_600311
  var valid_600312 = query.getOrDefault("Marker")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "Marker", valid_600312
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
  var valid_600313 = header.getOrDefault("X-Amz-Date")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Date", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Security-Token")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Security-Token", valid_600314
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600315 = header.getOrDefault("X-Amz-Target")
  valid_600315 = validateParameter(valid_600315, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeOrderableReplicationInstances"))
  if valid_600315 != nil:
    section.add "X-Amz-Target", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Content-Sha256", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-Algorithm")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Algorithm", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Signature")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Signature", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-SignedHeaders", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Credential")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Credential", valid_600320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600322: Call_DescribeOrderableReplicationInstances_600308;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication instance types that can be created in the specified region.
  ## 
  let valid = call_600322.validator(path, query, header, formData, body)
  let scheme = call_600322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600322.url(scheme.get, call_600322.host, call_600322.base,
                         call_600322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600322, url, valid)

proc call*(call_600323: Call_DescribeOrderableReplicationInstances_600308;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeOrderableReplicationInstances
  ## Returns information about the replication instance types that can be created in the specified region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600324 = newJObject()
  var body_600325 = newJObject()
  add(query_600324, "MaxRecords", newJString(MaxRecords))
  add(query_600324, "Marker", newJString(Marker))
  if body != nil:
    body_600325 = body
  result = call_600323.call(nil, query_600324, nil, nil, body_600325)

var describeOrderableReplicationInstances* = Call_DescribeOrderableReplicationInstances_600308(
    name: "describeOrderableReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances",
    validator: validate_DescribeOrderableReplicationInstances_600309, base: "/",
    url: url_DescribeOrderableReplicationInstances_600310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingMaintenanceActions_600326 = ref object of OpenApiRestCall_599368
proc url_DescribePendingMaintenanceActions_600328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePendingMaintenanceActions_600327(path: JsonNode;
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
  var valid_600329 = query.getOrDefault("MaxRecords")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "MaxRecords", valid_600329
  var valid_600330 = query.getOrDefault("Marker")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "Marker", valid_600330
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
  var valid_600331 = header.getOrDefault("X-Amz-Date")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Date", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-Security-Token")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Security-Token", valid_600332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600333 = header.getOrDefault("X-Amz-Target")
  valid_600333 = validateParameter(valid_600333, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribePendingMaintenanceActions"))
  if valid_600333 != nil:
    section.add "X-Amz-Target", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Content-Sha256", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Algorithm")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Algorithm", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Signature")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Signature", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-SignedHeaders", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Credential")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Credential", valid_600338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600340: Call_DescribePendingMaintenanceActions_600326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For internal use only
  ## 
  let valid = call_600340.validator(path, query, header, formData, body)
  let scheme = call_600340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600340.url(scheme.get, call_600340.host, call_600340.base,
                         call_600340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600340, url, valid)

proc call*(call_600341: Call_DescribePendingMaintenanceActions_600326;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describePendingMaintenanceActions
  ## For internal use only
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600342 = newJObject()
  var body_600343 = newJObject()
  add(query_600342, "MaxRecords", newJString(MaxRecords))
  add(query_600342, "Marker", newJString(Marker))
  if body != nil:
    body_600343 = body
  result = call_600341.call(nil, query_600342, nil, nil, body_600343)

var describePendingMaintenanceActions* = Call_DescribePendingMaintenanceActions_600326(
    name: "describePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions",
    validator: validate_DescribePendingMaintenanceActions_600327, base: "/",
    url: url_DescribePendingMaintenanceActions_600328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRefreshSchemasStatus_600344 = ref object of OpenApiRestCall_599368
proc url_DescribeRefreshSchemasStatus_600346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRefreshSchemasStatus_600345(path: JsonNode; query: JsonNode;
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
  var valid_600347 = header.getOrDefault("X-Amz-Date")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Date", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Security-Token")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Security-Token", valid_600348
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600349 = header.getOrDefault("X-Amz-Target")
  valid_600349 = validateParameter(valid_600349, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeRefreshSchemasStatus"))
  if valid_600349 != nil:
    section.add "X-Amz-Target", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Content-Sha256", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Algorithm")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Algorithm", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Signature")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Signature", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-SignedHeaders", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Credential")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Credential", valid_600354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600356: Call_DescribeRefreshSchemasStatus_600344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of the RefreshSchemas operation.
  ## 
  let valid = call_600356.validator(path, query, header, formData, body)
  let scheme = call_600356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600356.url(scheme.get, call_600356.host, call_600356.base,
                         call_600356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600356, url, valid)

proc call*(call_600357: Call_DescribeRefreshSchemasStatus_600344; body: JsonNode): Recallable =
  ## describeRefreshSchemasStatus
  ## Returns the status of the RefreshSchemas operation.
  ##   body: JObject (required)
  var body_600358 = newJObject()
  if body != nil:
    body_600358 = body
  result = call_600357.call(nil, nil, nil, nil, body_600358)

var describeRefreshSchemasStatus* = Call_DescribeRefreshSchemasStatus_600344(
    name: "describeRefreshSchemasStatus", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus",
    validator: validate_DescribeRefreshSchemasStatus_600345, base: "/",
    url: url_DescribeRefreshSchemasStatus_600346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstanceTaskLogs_600359 = ref object of OpenApiRestCall_599368
proc url_DescribeReplicationInstanceTaskLogs_600361(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReplicationInstanceTaskLogs_600360(path: JsonNode;
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
  var valid_600362 = query.getOrDefault("MaxRecords")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "MaxRecords", valid_600362
  var valid_600363 = query.getOrDefault("Marker")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "Marker", valid_600363
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
      "AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"))
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

proc call*(call_600373: Call_DescribeReplicationInstanceTaskLogs_600359;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the task logs for the specified task.
  ## 
  let valid = call_600373.validator(path, query, header, formData, body)
  let scheme = call_600373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600373.url(scheme.get, call_600373.host, call_600373.base,
                         call_600373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600373, url, valid)

proc call*(call_600374: Call_DescribeReplicationInstanceTaskLogs_600359;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstanceTaskLogs
  ## Returns information about the task logs for the specified task.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600375 = newJObject()
  var body_600376 = newJObject()
  add(query_600375, "MaxRecords", newJString(MaxRecords))
  add(query_600375, "Marker", newJString(Marker))
  if body != nil:
    body_600376 = body
  result = call_600374.call(nil, query_600375, nil, nil, body_600376)

var describeReplicationInstanceTaskLogs* = Call_DescribeReplicationInstanceTaskLogs_600359(
    name: "describeReplicationInstanceTaskLogs", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs",
    validator: validate_DescribeReplicationInstanceTaskLogs_600360, base: "/",
    url: url_DescribeReplicationInstanceTaskLogs_600361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstances_600377 = ref object of OpenApiRestCall_599368
proc url_DescribeReplicationInstances_600379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReplicationInstances_600378(path: JsonNode; query: JsonNode;
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
  var valid_600380 = query.getOrDefault("MaxRecords")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "MaxRecords", valid_600380
  var valid_600381 = query.getOrDefault("Marker")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "Marker", valid_600381
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
  var valid_600382 = header.getOrDefault("X-Amz-Date")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Date", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Security-Token")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Security-Token", valid_600383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600384 = header.getOrDefault("X-Amz-Target")
  valid_600384 = validateParameter(valid_600384, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstances"))
  if valid_600384 != nil:
    section.add "X-Amz-Target", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600391: Call_DescribeReplicationInstances_600377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication instances for your account in the current region.
  ## 
  let valid = call_600391.validator(path, query, header, formData, body)
  let scheme = call_600391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600391.url(scheme.get, call_600391.host, call_600391.base,
                         call_600391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600391, url, valid)

proc call*(call_600392: Call_DescribeReplicationInstances_600377; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstances
  ## Returns information about replication instances for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600393 = newJObject()
  var body_600394 = newJObject()
  add(query_600393, "MaxRecords", newJString(MaxRecords))
  add(query_600393, "Marker", newJString(Marker))
  if body != nil:
    body_600394 = body
  result = call_600392.call(nil, query_600393, nil, nil, body_600394)

var describeReplicationInstances* = Call_DescribeReplicationInstances_600377(
    name: "describeReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances",
    validator: validate_DescribeReplicationInstances_600378, base: "/",
    url: url_DescribeReplicationInstances_600379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationSubnetGroups_600395 = ref object of OpenApiRestCall_599368
proc url_DescribeReplicationSubnetGroups_600397(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReplicationSubnetGroups_600396(path: JsonNode;
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
  var valid_600398 = query.getOrDefault("MaxRecords")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "MaxRecords", valid_600398
  var valid_600399 = query.getOrDefault("Marker")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "Marker", valid_600399
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
  var valid_600400 = header.getOrDefault("X-Amz-Date")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Date", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Security-Token")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Security-Token", valid_600401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600402 = header.getOrDefault("X-Amz-Target")
  valid_600402 = validateParameter(valid_600402, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationSubnetGroups"))
  if valid_600402 != nil:
    section.add "X-Amz-Target", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Content-Sha256", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Algorithm")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Algorithm", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Signature")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Signature", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-SignedHeaders", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Credential")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Credential", valid_600407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600409: Call_DescribeReplicationSubnetGroups_600395;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication subnet groups.
  ## 
  let valid = call_600409.validator(path, query, header, formData, body)
  let scheme = call_600409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600409.url(scheme.get, call_600409.host, call_600409.base,
                         call_600409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600409, url, valid)

proc call*(call_600410: Call_DescribeReplicationSubnetGroups_600395;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationSubnetGroups
  ## Returns information about the replication subnet groups.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600411 = newJObject()
  var body_600412 = newJObject()
  add(query_600411, "MaxRecords", newJString(MaxRecords))
  add(query_600411, "Marker", newJString(Marker))
  if body != nil:
    body_600412 = body
  result = call_600410.call(nil, query_600411, nil, nil, body_600412)

var describeReplicationSubnetGroups* = Call_DescribeReplicationSubnetGroups_600395(
    name: "describeReplicationSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups",
    validator: validate_DescribeReplicationSubnetGroups_600396, base: "/",
    url: url_DescribeReplicationSubnetGroups_600397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTaskAssessmentResults_600413 = ref object of OpenApiRestCall_599368
proc url_DescribeReplicationTaskAssessmentResults_600415(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReplicationTaskAssessmentResults_600414(path: JsonNode;
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
  var valid_600416 = query.getOrDefault("MaxRecords")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "MaxRecords", valid_600416
  var valid_600417 = query.getOrDefault("Marker")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "Marker", valid_600417
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
  var valid_600418 = header.getOrDefault("X-Amz-Date")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Date", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Security-Token")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Security-Token", valid_600419
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600420 = header.getOrDefault("X-Amz-Target")
  valid_600420 = validateParameter(valid_600420, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"))
  if valid_600420 != nil:
    section.add "X-Amz-Target", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Content-Sha256", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Algorithm")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Algorithm", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Signature")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Signature", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-SignedHeaders", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-Credential")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Credential", valid_600425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600427: Call_DescribeReplicationTaskAssessmentResults_600413;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ## 
  let valid = call_600427.validator(path, query, header, formData, body)
  let scheme = call_600427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600427.url(scheme.get, call_600427.host, call_600427.base,
                         call_600427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600427, url, valid)

proc call*(call_600428: Call_DescribeReplicationTaskAssessmentResults_600413;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTaskAssessmentResults
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600429 = newJObject()
  var body_600430 = newJObject()
  add(query_600429, "MaxRecords", newJString(MaxRecords))
  add(query_600429, "Marker", newJString(Marker))
  if body != nil:
    body_600430 = body
  result = call_600428.call(nil, query_600429, nil, nil, body_600430)

var describeReplicationTaskAssessmentResults* = Call_DescribeReplicationTaskAssessmentResults_600413(
    name: "describeReplicationTaskAssessmentResults", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults",
    validator: validate_DescribeReplicationTaskAssessmentResults_600414,
    base: "/", url: url_DescribeReplicationTaskAssessmentResults_600415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTasks_600431 = ref object of OpenApiRestCall_599368
proc url_DescribeReplicationTasks_600433(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReplicationTasks_600432(path: JsonNode; query: JsonNode;
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
  var valid_600434 = query.getOrDefault("MaxRecords")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "MaxRecords", valid_600434
  var valid_600435 = query.getOrDefault("Marker")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "Marker", valid_600435
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
  var valid_600436 = header.getOrDefault("X-Amz-Date")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Date", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Security-Token")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Security-Token", valid_600437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600438 = header.getOrDefault("X-Amz-Target")
  valid_600438 = validateParameter(valid_600438, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTasks"))
  if valid_600438 != nil:
    section.add "X-Amz-Target", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Content-Sha256", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Algorithm")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Algorithm", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Signature")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Signature", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-SignedHeaders", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Credential")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Credential", valid_600443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600445: Call_DescribeReplicationTasks_600431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication tasks for your account in the current region.
  ## 
  let valid = call_600445.validator(path, query, header, formData, body)
  let scheme = call_600445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600445.url(scheme.get, call_600445.host, call_600445.base,
                         call_600445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600445, url, valid)

proc call*(call_600446: Call_DescribeReplicationTasks_600431; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTasks
  ## Returns information about replication tasks for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600447 = newJObject()
  var body_600448 = newJObject()
  add(query_600447, "MaxRecords", newJString(MaxRecords))
  add(query_600447, "Marker", newJString(Marker))
  if body != nil:
    body_600448 = body
  result = call_600446.call(nil, query_600447, nil, nil, body_600448)

var describeReplicationTasks* = Call_DescribeReplicationTasks_600431(
    name: "describeReplicationTasks", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks",
    validator: validate_DescribeReplicationTasks_600432, base: "/",
    url: url_DescribeReplicationTasks_600433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchemas_600449 = ref object of OpenApiRestCall_599368
proc url_DescribeSchemas_600451(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSchemas_600450(path: JsonNode; query: JsonNode;
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
  var valid_600452 = query.getOrDefault("MaxRecords")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "MaxRecords", valid_600452
  var valid_600453 = query.getOrDefault("Marker")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "Marker", valid_600453
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
  var valid_600454 = header.getOrDefault("X-Amz-Date")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Date", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Security-Token")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Security-Token", valid_600455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600456 = header.getOrDefault("X-Amz-Target")
  valid_600456 = validateParameter(valid_600456, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeSchemas"))
  if valid_600456 != nil:
    section.add "X-Amz-Target", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Content-Sha256", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Algorithm")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Algorithm", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Signature")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Signature", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-SignedHeaders", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Credential")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Credential", valid_600461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600463: Call_DescribeSchemas_600449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ## 
  let valid = call_600463.validator(path, query, header, formData, body)
  let scheme = call_600463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600463.url(scheme.get, call_600463.host, call_600463.base,
                         call_600463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600463, url, valid)

proc call*(call_600464: Call_DescribeSchemas_600449; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeSchemas
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600465 = newJObject()
  var body_600466 = newJObject()
  add(query_600465, "MaxRecords", newJString(MaxRecords))
  add(query_600465, "Marker", newJString(Marker))
  if body != nil:
    body_600466 = body
  result = call_600464.call(nil, query_600465, nil, nil, body_600466)

var describeSchemas* = Call_DescribeSchemas_600449(name: "describeSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas",
    validator: validate_DescribeSchemas_600450, base: "/", url: url_DescribeSchemas_600451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTableStatistics_600467 = ref object of OpenApiRestCall_599368
proc url_DescribeTableStatistics_600469(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTableStatistics_600468(path: JsonNode; query: JsonNode;
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
  var valid_600470 = query.getOrDefault("MaxRecords")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "MaxRecords", valid_600470
  var valid_600471 = query.getOrDefault("Marker")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "Marker", valid_600471
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
  var valid_600472 = header.getOrDefault("X-Amz-Date")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Date", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Security-Token")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Security-Token", valid_600473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600474 = header.getOrDefault("X-Amz-Target")
  valid_600474 = validateParameter(valid_600474, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeTableStatistics"))
  if valid_600474 != nil:
    section.add "X-Amz-Target", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Content-Sha256", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Algorithm")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Algorithm", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Signature")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Signature", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-SignedHeaders", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Credential")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Credential", valid_600479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600481: Call_DescribeTableStatistics_600467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ## 
  let valid = call_600481.validator(path, query, header, formData, body)
  let scheme = call_600481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600481.url(scheme.get, call_600481.host, call_600481.base,
                         call_600481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600481, url, valid)

proc call*(call_600482: Call_DescribeTableStatistics_600467; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeTableStatistics
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_600483 = newJObject()
  var body_600484 = newJObject()
  add(query_600483, "MaxRecords", newJString(MaxRecords))
  add(query_600483, "Marker", newJString(Marker))
  if body != nil:
    body_600484 = body
  result = call_600482.call(nil, query_600483, nil, nil, body_600484)

var describeTableStatistics* = Call_DescribeTableStatistics_600467(
    name: "describeTableStatistics", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics",
    validator: validate_DescribeTableStatistics_600468, base: "/",
    url: url_DescribeTableStatistics_600469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificate_600485 = ref object of OpenApiRestCall_599368
proc url_ImportCertificate_600487(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportCertificate_600486(path: JsonNode; query: JsonNode;
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
  var valid_600488 = header.getOrDefault("X-Amz-Date")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Date", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Security-Token")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Security-Token", valid_600489
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600490 = header.getOrDefault("X-Amz-Target")
  valid_600490 = validateParameter(valid_600490, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ImportCertificate"))
  if valid_600490 != nil:
    section.add "X-Amz-Target", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Content-Sha256", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Algorithm")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Algorithm", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Signature")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Signature", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-SignedHeaders", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Credential")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Credential", valid_600495
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600497: Call_ImportCertificate_600485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads the specified certificate.
  ## 
  let valid = call_600497.validator(path, query, header, formData, body)
  let scheme = call_600497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600497.url(scheme.get, call_600497.host, call_600497.base,
                         call_600497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600497, url, valid)

proc call*(call_600498: Call_ImportCertificate_600485; body: JsonNode): Recallable =
  ## importCertificate
  ## Uploads the specified certificate.
  ##   body: JObject (required)
  var body_600499 = newJObject()
  if body != nil:
    body_600499 = body
  result = call_600498.call(nil, nil, nil, nil, body_600499)

var importCertificate* = Call_ImportCertificate_600485(name: "importCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ImportCertificate",
    validator: validate_ImportCertificate_600486, base: "/",
    url: url_ImportCertificate_600487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600500 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600502(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600501(path: JsonNode; query: JsonNode;
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
  var valid_600503 = header.getOrDefault("X-Amz-Date")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Date", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Security-Token")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Security-Token", valid_600504
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600505 = header.getOrDefault("X-Amz-Target")
  valid_600505 = validateParameter(valid_600505, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ListTagsForResource"))
  if valid_600505 != nil:
    section.add "X-Amz-Target", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Content-Sha256", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Algorithm")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Algorithm", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Signature")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Signature", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-SignedHeaders", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Credential")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Credential", valid_600510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600512: Call_ListTagsForResource_600500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for an AWS DMS resource.
  ## 
  let valid = call_600512.validator(path, query, header, formData, body)
  let scheme = call_600512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600512.url(scheme.get, call_600512.host, call_600512.base,
                         call_600512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600512, url, valid)

proc call*(call_600513: Call_ListTagsForResource_600500; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags for an AWS DMS resource.
  ##   body: JObject (required)
  var body_600514 = newJObject()
  if body != nil:
    body_600514 = body
  result = call_600513.call(nil, nil, nil, nil, body_600514)

var listTagsForResource* = Call_ListTagsForResource_600500(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource",
    validator: validate_ListTagsForResource_600501, base: "/",
    url: url_ListTagsForResource_600502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEndpoint_600515 = ref object of OpenApiRestCall_599368
proc url_ModifyEndpoint_600517(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyEndpoint_600516(path: JsonNode; query: JsonNode;
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
  var valid_600518 = header.getOrDefault("X-Amz-Date")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Date", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Security-Token")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Security-Token", valid_600519
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600520 = header.getOrDefault("X-Amz-Target")
  valid_600520 = validateParameter(valid_600520, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEndpoint"))
  if valid_600520 != nil:
    section.add "X-Amz-Target", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Content-Sha256", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Algorithm")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Algorithm", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Signature")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Signature", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-SignedHeaders", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Credential")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Credential", valid_600525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600527: Call_ModifyEndpoint_600515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified endpoint.
  ## 
  let valid = call_600527.validator(path, query, header, formData, body)
  let scheme = call_600527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600527.url(scheme.get, call_600527.host, call_600527.base,
                         call_600527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600527, url, valid)

proc call*(call_600528: Call_ModifyEndpoint_600515; body: JsonNode): Recallable =
  ## modifyEndpoint
  ## Modifies the specified endpoint.
  ##   body: JObject (required)
  var body_600529 = newJObject()
  if body != nil:
    body_600529 = body
  result = call_600528.call(nil, nil, nil, nil, body_600529)

var modifyEndpoint* = Call_ModifyEndpoint_600515(name: "modifyEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint",
    validator: validate_ModifyEndpoint_600516, base: "/", url: url_ModifyEndpoint_600517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEventSubscription_600530 = ref object of OpenApiRestCall_599368
proc url_ModifyEventSubscription_600532(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyEventSubscription_600531(path: JsonNode; query: JsonNode;
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
  var valid_600533 = header.getOrDefault("X-Amz-Date")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Date", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-Security-Token")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Security-Token", valid_600534
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600535 = header.getOrDefault("X-Amz-Target")
  valid_600535 = validateParameter(valid_600535, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEventSubscription"))
  if valid_600535 != nil:
    section.add "X-Amz-Target", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Content-Sha256", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Algorithm")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Algorithm", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Signature")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Signature", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-SignedHeaders", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Credential")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Credential", valid_600540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600542: Call_ModifyEventSubscription_600530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing AWS DMS event notification subscription. 
  ## 
  let valid = call_600542.validator(path, query, header, formData, body)
  let scheme = call_600542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600542.url(scheme.get, call_600542.host, call_600542.base,
                         call_600542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600542, url, valid)

proc call*(call_600543: Call_ModifyEventSubscription_600530; body: JsonNode): Recallable =
  ## modifyEventSubscription
  ## Modifies an existing AWS DMS event notification subscription. 
  ##   body: JObject (required)
  var body_600544 = newJObject()
  if body != nil:
    body_600544 = body
  result = call_600543.call(nil, nil, nil, nil, body_600544)

var modifyEventSubscription* = Call_ModifyEventSubscription_600530(
    name: "modifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription",
    validator: validate_ModifyEventSubscription_600531, base: "/",
    url: url_ModifyEventSubscription_600532, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationInstance_600545 = ref object of OpenApiRestCall_599368
proc url_ModifyReplicationInstance_600547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyReplicationInstance_600546(path: JsonNode; query: JsonNode;
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
  var valid_600548 = header.getOrDefault("X-Amz-Date")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Date", valid_600548
  var valid_600549 = header.getOrDefault("X-Amz-Security-Token")
  valid_600549 = validateParameter(valid_600549, JString, required = false,
                                 default = nil)
  if valid_600549 != nil:
    section.add "X-Amz-Security-Token", valid_600549
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600550 = header.getOrDefault("X-Amz-Target")
  valid_600550 = validateParameter(valid_600550, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationInstance"))
  if valid_600550 != nil:
    section.add "X-Amz-Target", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Content-Sha256", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Algorithm")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Algorithm", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-Signature")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Signature", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-SignedHeaders", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Credential")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Credential", valid_600555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600557: Call_ModifyReplicationInstance_600545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ## 
  let valid = call_600557.validator(path, query, header, formData, body)
  let scheme = call_600557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600557.url(scheme.get, call_600557.host, call_600557.base,
                         call_600557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600557, url, valid)

proc call*(call_600558: Call_ModifyReplicationInstance_600545; body: JsonNode): Recallable =
  ## modifyReplicationInstance
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ##   body: JObject (required)
  var body_600559 = newJObject()
  if body != nil:
    body_600559 = body
  result = call_600558.call(nil, nil, nil, nil, body_600559)

var modifyReplicationInstance* = Call_ModifyReplicationInstance_600545(
    name: "modifyReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance",
    validator: validate_ModifyReplicationInstance_600546, base: "/",
    url: url_ModifyReplicationInstance_600547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationSubnetGroup_600560 = ref object of OpenApiRestCall_599368
proc url_ModifyReplicationSubnetGroup_600562(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyReplicationSubnetGroup_600561(path: JsonNode; query: JsonNode;
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
  var valid_600563 = header.getOrDefault("X-Amz-Date")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Date", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Security-Token")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Security-Token", valid_600564
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600565 = header.getOrDefault("X-Amz-Target")
  valid_600565 = validateParameter(valid_600565, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationSubnetGroup"))
  if valid_600565 != nil:
    section.add "X-Amz-Target", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Content-Sha256", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Algorithm")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Algorithm", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-Signature")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Signature", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-SignedHeaders", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Credential")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Credential", valid_600570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600572: Call_ModifyReplicationSubnetGroup_600560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for the specified replication subnet group.
  ## 
  let valid = call_600572.validator(path, query, header, formData, body)
  let scheme = call_600572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600572.url(scheme.get, call_600572.host, call_600572.base,
                         call_600572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600572, url, valid)

proc call*(call_600573: Call_ModifyReplicationSubnetGroup_600560; body: JsonNode): Recallable =
  ## modifyReplicationSubnetGroup
  ## Modifies the settings for the specified replication subnet group.
  ##   body: JObject (required)
  var body_600574 = newJObject()
  if body != nil:
    body_600574 = body
  result = call_600573.call(nil, nil, nil, nil, body_600574)

var modifyReplicationSubnetGroup* = Call_ModifyReplicationSubnetGroup_600560(
    name: "modifyReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup",
    validator: validate_ModifyReplicationSubnetGroup_600561, base: "/",
    url: url_ModifyReplicationSubnetGroup_600562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationTask_600575 = ref object of OpenApiRestCall_599368
proc url_ModifyReplicationTask_600577(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyReplicationTask_600576(path: JsonNode; query: JsonNode;
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
  var valid_600578 = header.getOrDefault("X-Amz-Date")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Date", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-Security-Token")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-Security-Token", valid_600579
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600580 = header.getOrDefault("X-Amz-Target")
  valid_600580 = validateParameter(valid_600580, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationTask"))
  if valid_600580 != nil:
    section.add "X-Amz-Target", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Content-Sha256", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Algorithm")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Algorithm", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-Signature")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Signature", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-SignedHeaders", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Credential")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Credential", valid_600585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600587: Call_ModifyReplicationTask_600575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ## 
  let valid = call_600587.validator(path, query, header, formData, body)
  let scheme = call_600587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600587.url(scheme.get, call_600587.host, call_600587.base,
                         call_600587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600587, url, valid)

proc call*(call_600588: Call_ModifyReplicationTask_600575; body: JsonNode): Recallable =
  ## modifyReplicationTask
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600589 = newJObject()
  if body != nil:
    body_600589 = body
  result = call_600588.call(nil, nil, nil, nil, body_600589)

var modifyReplicationTask* = Call_ModifyReplicationTask_600575(
    name: "modifyReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask",
    validator: validate_ModifyReplicationTask_600576, base: "/",
    url: url_ModifyReplicationTask_600577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootReplicationInstance_600590 = ref object of OpenApiRestCall_599368
proc url_RebootReplicationInstance_600592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RebootReplicationInstance_600591(path: JsonNode; query: JsonNode;
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
  var valid_600593 = header.getOrDefault("X-Amz-Date")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Date", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Security-Token")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Security-Token", valid_600594
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600595 = header.getOrDefault("X-Amz-Target")
  valid_600595 = validateParameter(valid_600595, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RebootReplicationInstance"))
  if valid_600595 != nil:
    section.add "X-Amz-Target", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Content-Sha256", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Algorithm")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Algorithm", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-Signature")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Signature", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-SignedHeaders", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Credential")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Credential", valid_600600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600602: Call_RebootReplicationInstance_600590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ## 
  let valid = call_600602.validator(path, query, header, formData, body)
  let scheme = call_600602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600602.url(scheme.get, call_600602.host, call_600602.base,
                         call_600602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600602, url, valid)

proc call*(call_600603: Call_RebootReplicationInstance_600590; body: JsonNode): Recallable =
  ## rebootReplicationInstance
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ##   body: JObject (required)
  var body_600604 = newJObject()
  if body != nil:
    body_600604 = body
  result = call_600603.call(nil, nil, nil, nil, body_600604)

var rebootReplicationInstance* = Call_RebootReplicationInstance_600590(
    name: "rebootReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance",
    validator: validate_RebootReplicationInstance_600591, base: "/",
    url: url_RebootReplicationInstance_600592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshSchemas_600605 = ref object of OpenApiRestCall_599368
proc url_RefreshSchemas_600607(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RefreshSchemas_600606(path: JsonNode; query: JsonNode;
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
  var valid_600608 = header.getOrDefault("X-Amz-Date")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Date", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Security-Token")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Security-Token", valid_600609
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600610 = header.getOrDefault("X-Amz-Target")
  valid_600610 = validateParameter(valid_600610, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RefreshSchemas"))
  if valid_600610 != nil:
    section.add "X-Amz-Target", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Content-Sha256", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Algorithm")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Algorithm", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-Signature")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-Signature", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-SignedHeaders", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-Credential")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-Credential", valid_600615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600617: Call_RefreshSchemas_600605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ## 
  let valid = call_600617.validator(path, query, header, formData, body)
  let scheme = call_600617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600617.url(scheme.get, call_600617.host, call_600617.base,
                         call_600617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600617, url, valid)

proc call*(call_600618: Call_RefreshSchemas_600605; body: JsonNode): Recallable =
  ## refreshSchemas
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ##   body: JObject (required)
  var body_600619 = newJObject()
  if body != nil:
    body_600619 = body
  result = call_600618.call(nil, nil, nil, nil, body_600619)

var refreshSchemas* = Call_RefreshSchemas_600605(name: "refreshSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas",
    validator: validate_RefreshSchemas_600606, base: "/", url: url_RefreshSchemas_600607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReloadTables_600620 = ref object of OpenApiRestCall_599368
proc url_ReloadTables_600622(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReloadTables_600621(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600623 = header.getOrDefault("X-Amz-Date")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Date", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Security-Token")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Security-Token", valid_600624
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600625 = header.getOrDefault("X-Amz-Target")
  valid_600625 = validateParameter(valid_600625, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ReloadTables"))
  if valid_600625 != nil:
    section.add "X-Amz-Target", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Content-Sha256", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Algorithm")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Algorithm", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Signature")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Signature", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-SignedHeaders", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Credential")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Credential", valid_600630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600632: Call_ReloadTables_600620; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reloads the target database table with the source data. 
  ## 
  let valid = call_600632.validator(path, query, header, formData, body)
  let scheme = call_600632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600632.url(scheme.get, call_600632.host, call_600632.base,
                         call_600632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600632, url, valid)

proc call*(call_600633: Call_ReloadTables_600620; body: JsonNode): Recallable =
  ## reloadTables
  ## Reloads the target database table with the source data. 
  ##   body: JObject (required)
  var body_600634 = newJObject()
  if body != nil:
    body_600634 = body
  result = call_600633.call(nil, nil, nil, nil, body_600634)

var reloadTables* = Call_ReloadTables_600620(name: "reloadTables",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ReloadTables",
    validator: validate_ReloadTables_600621, base: "/", url: url_ReloadTables_600622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_600635 = ref object of OpenApiRestCall_599368
proc url_RemoveTagsFromResource_600637(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromResource_600636(path: JsonNode; query: JsonNode;
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
  var valid_600638 = header.getOrDefault("X-Amz-Date")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Date", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Security-Token")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Security-Token", valid_600639
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600640 = header.getOrDefault("X-Amz-Target")
  valid_600640 = validateParameter(valid_600640, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RemoveTagsFromResource"))
  if valid_600640 != nil:
    section.add "X-Amz-Target", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Content-Sha256", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Algorithm")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Algorithm", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Signature")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Signature", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-SignedHeaders", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Credential")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Credential", valid_600645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600647: Call_RemoveTagsFromResource_600635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a DMS resource.
  ## 
  let valid = call_600647.validator(path, query, header, formData, body)
  let scheme = call_600647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600647.url(scheme.get, call_600647.host, call_600647.base,
                         call_600647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600647, url, valid)

proc call*(call_600648: Call_RemoveTagsFromResource_600635; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes metadata tags from a DMS resource.
  ##   body: JObject (required)
  var body_600649 = newJObject()
  if body != nil:
    body_600649 = body
  result = call_600648.call(nil, nil, nil, nil, body_600649)

var removeTagsFromResource* = Call_RemoveTagsFromResource_600635(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_600636, base: "/",
    url: url_RemoveTagsFromResource_600637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTask_600650 = ref object of OpenApiRestCall_599368
proc url_StartReplicationTask_600652(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartReplicationTask_600651(path: JsonNode; query: JsonNode;
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
  var valid_600653 = header.getOrDefault("X-Amz-Date")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Date", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Security-Token")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Security-Token", valid_600654
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600655 = header.getOrDefault("X-Amz-Target")
  valid_600655 = validateParameter(valid_600655, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTask"))
  if valid_600655 != nil:
    section.add "X-Amz-Target", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Content-Sha256", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Algorithm")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Algorithm", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-Signature")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-Signature", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-SignedHeaders", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-Credential")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-Credential", valid_600660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600662: Call_StartReplicationTask_600650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_600662.validator(path, query, header, formData, body)
  let scheme = call_600662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600662.url(scheme.get, call_600662.host, call_600662.base,
                         call_600662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600662, url, valid)

proc call*(call_600663: Call_StartReplicationTask_600650; body: JsonNode): Recallable =
  ## startReplicationTask
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_600664 = newJObject()
  if body != nil:
    body_600664 = body
  result = call_600663.call(nil, nil, nil, nil, body_600664)

var startReplicationTask* = Call_StartReplicationTask_600650(
    name: "startReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask",
    validator: validate_StartReplicationTask_600651, base: "/",
    url: url_StartReplicationTask_600652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTaskAssessment_600665 = ref object of OpenApiRestCall_599368
proc url_StartReplicationTaskAssessment_600667(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartReplicationTaskAssessment_600666(path: JsonNode;
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
  var valid_600668 = header.getOrDefault("X-Amz-Date")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Date", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Security-Token")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Security-Token", valid_600669
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600670 = header.getOrDefault("X-Amz-Target")
  valid_600670 = validateParameter(valid_600670, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTaskAssessment"))
  if valid_600670 != nil:
    section.add "X-Amz-Target", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Content-Sha256", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Algorithm")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Algorithm", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-Signature")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-Signature", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-SignedHeaders", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Credential")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Credential", valid_600675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600677: Call_StartReplicationTaskAssessment_600665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ## 
  let valid = call_600677.validator(path, query, header, formData, body)
  let scheme = call_600677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600677.url(scheme.get, call_600677.host, call_600677.base,
                         call_600677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600677, url, valid)

proc call*(call_600678: Call_StartReplicationTaskAssessment_600665; body: JsonNode): Recallable =
  ## startReplicationTaskAssessment
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ##   body: JObject (required)
  var body_600679 = newJObject()
  if body != nil:
    body_600679 = body
  result = call_600678.call(nil, nil, nil, nil, body_600679)

var startReplicationTaskAssessment* = Call_StartReplicationTaskAssessment_600665(
    name: "startReplicationTaskAssessment", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment",
    validator: validate_StartReplicationTaskAssessment_600666, base: "/",
    url: url_StartReplicationTaskAssessment_600667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopReplicationTask_600680 = ref object of OpenApiRestCall_599368
proc url_StopReplicationTask_600682(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopReplicationTask_600681(path: JsonNode; query: JsonNode;
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
  var valid_600683 = header.getOrDefault("X-Amz-Date")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Date", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Security-Token")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Security-Token", valid_600684
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600685 = header.getOrDefault("X-Amz-Target")
  valid_600685 = validateParameter(valid_600685, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StopReplicationTask"))
  if valid_600685 != nil:
    section.add "X-Amz-Target", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Content-Sha256", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Algorithm")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Algorithm", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Signature")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Signature", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-SignedHeaders", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Credential")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Credential", valid_600690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600692: Call_StopReplicationTask_600680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops the replication task.</p> <p/>
  ## 
  let valid = call_600692.validator(path, query, header, formData, body)
  let scheme = call_600692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600692.url(scheme.get, call_600692.host, call_600692.base,
                         call_600692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600692, url, valid)

proc call*(call_600693: Call_StopReplicationTask_600680; body: JsonNode): Recallable =
  ## stopReplicationTask
  ## <p>Stops the replication task.</p> <p/>
  ##   body: JObject (required)
  var body_600694 = newJObject()
  if body != nil:
    body_600694 = body
  result = call_600693.call(nil, nil, nil, nil, body_600694)

var stopReplicationTask* = Call_StopReplicationTask_600680(
    name: "stopReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask",
    validator: validate_StopReplicationTask_600681, base: "/",
    url: url_StopReplicationTask_600682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestConnection_600695 = ref object of OpenApiRestCall_599368
proc url_TestConnection_600697(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestConnection_600696(path: JsonNode; query: JsonNode;
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
  var valid_600698 = header.getOrDefault("X-Amz-Date")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Date", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-Security-Token")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Security-Token", valid_600699
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600700 = header.getOrDefault("X-Amz-Target")
  valid_600700 = validateParameter(valid_600700, JString, required = true, default = newJString(
      "AmazonDMSv20160101.TestConnection"))
  if valid_600700 != nil:
    section.add "X-Amz-Target", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Content-Sha256", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Algorithm")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Algorithm", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Signature")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Signature", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-SignedHeaders", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Credential")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Credential", valid_600705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600707: Call_TestConnection_600695; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the connection between the replication instance and the endpoint.
  ## 
  let valid = call_600707.validator(path, query, header, formData, body)
  let scheme = call_600707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600707.url(scheme.get, call_600707.host, call_600707.base,
                         call_600707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600707, url, valid)

proc call*(call_600708: Call_TestConnection_600695; body: JsonNode): Recallable =
  ## testConnection
  ## Tests the connection between the replication instance and the endpoint.
  ##   body: JObject (required)
  var body_600709 = newJObject()
  if body != nil:
    body_600709 = body
  result = call_600708.call(nil, nil, nil, nil, body_600709)

var testConnection* = Call_TestConnection_600695(name: "testConnection",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.TestConnection",
    validator: validate_TestConnection_600696, base: "/", url: url_TestConnection_600697,
    schemes: {Scheme.Https, Scheme.Http})
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
