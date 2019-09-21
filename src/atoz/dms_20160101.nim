
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToResource_602770 = ref object of OpenApiRestCall_602433
proc url_AddTagsToResource_602772(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTagsToResource_602771(path: JsonNode; query: JsonNode;
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
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "AmazonDMSv20160101.AddTagsToResource"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_AddTagsToResource_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_AddTagsToResource_602770; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var addTagsToResource* = Call_AddTagsToResource_602770(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource",
    validator: validate_AddTagsToResource_602771, base: "/",
    url: url_AddTagsToResource_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplyPendingMaintenanceAction_603039 = ref object of OpenApiRestCall_602433
proc url_ApplyPendingMaintenanceAction_603041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ApplyPendingMaintenanceAction_603040(path: JsonNode; query: JsonNode;
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
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603044 = header.getOrDefault("X-Amz-Target")
  valid_603044 = validateParameter(valid_603044, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ApplyPendingMaintenanceAction"))
  if valid_603044 != nil:
    section.add "X-Amz-Target", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_ApplyPendingMaintenanceAction_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_ApplyPendingMaintenanceAction_603039; body: JsonNode): Recallable =
  ## applyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var applyPendingMaintenanceAction* = Call_ApplyPendingMaintenanceAction_603039(
    name: "applyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction",
    validator: validate_ApplyPendingMaintenanceAction_603040, base: "/",
    url: url_ApplyPendingMaintenanceAction_603041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_603054 = ref object of OpenApiRestCall_602433
proc url_CreateEndpoint_603056(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEndpoint_603055(path: JsonNode; query: JsonNode;
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
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603059 = header.getOrDefault("X-Amz-Target")
  valid_603059 = validateParameter(valid_603059, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEndpoint"))
  if valid_603059 != nil:
    section.add "X-Amz-Target", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_CreateEndpoint_603054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint using the provided settings.
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_CreateEndpoint_603054; body: JsonNode): Recallable =
  ## createEndpoint
  ## Creates an endpoint using the provided settings.
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var createEndpoint* = Call_CreateEndpoint_603054(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint",
    validator: validate_CreateEndpoint_603055, base: "/", url: url_CreateEndpoint_603056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSubscription_603069 = ref object of OpenApiRestCall_602433
proc url_CreateEventSubscription_603071(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEventSubscription_603070(path: JsonNode; query: JsonNode;
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
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603074 = header.getOrDefault("X-Amz-Target")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEventSubscription"))
  if valid_603074 != nil:
    section.add "X-Amz-Target", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_CreateEventSubscription_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_CreateEventSubscription_603069; body: JsonNode): Recallable =
  ## createEventSubscription
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var createEventSubscription* = Call_CreateEventSubscription_603069(
    name: "createEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription",
    validator: validate_CreateEventSubscription_603070, base: "/",
    url: url_CreateEventSubscription_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationInstance_603084 = ref object of OpenApiRestCall_602433
proc url_CreateReplicationInstance_603086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationInstance_603085(path: JsonNode; query: JsonNode;
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
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603089 = header.getOrDefault("X-Amz-Target")
  valid_603089 = validateParameter(valid_603089, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationInstance"))
  if valid_603089 != nil:
    section.add "X-Amz-Target", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Content-Sha256", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-SignedHeaders", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Credential")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Credential", valid_603094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_CreateReplicationInstance_603084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the replication instance using the specified parameters.
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_CreateReplicationInstance_603084; body: JsonNode): Recallable =
  ## createReplicationInstance
  ## Creates the replication instance using the specified parameters.
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var createReplicationInstance* = Call_CreateReplicationInstance_603084(
    name: "createReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance",
    validator: validate_CreateReplicationInstance_603085, base: "/",
    url: url_CreateReplicationInstance_603086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationSubnetGroup_603099 = ref object of OpenApiRestCall_602433
proc url_CreateReplicationSubnetGroup_603101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationSubnetGroup_603100(path: JsonNode; query: JsonNode;
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
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603104 = header.getOrDefault("X-Amz-Target")
  valid_603104 = validateParameter(valid_603104, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationSubnetGroup"))
  if valid_603104 != nil:
    section.add "X-Amz-Target", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_CreateReplicationSubnetGroup_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_CreateReplicationSubnetGroup_603099; body: JsonNode): Recallable =
  ## createReplicationSubnetGroup
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var createReplicationSubnetGroup* = Call_CreateReplicationSubnetGroup_603099(
    name: "createReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup",
    validator: validate_CreateReplicationSubnetGroup_603100, base: "/",
    url: url_CreateReplicationSubnetGroup_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationTask_603114 = ref object of OpenApiRestCall_602433
proc url_CreateReplicationTask_603116(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationTask_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603119 = header.getOrDefault("X-Amz-Target")
  valid_603119 = validateParameter(valid_603119, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationTask"))
  if valid_603119 != nil:
    section.add "X-Amz-Target", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_CreateReplicationTask_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication task using the specified parameters.
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_CreateReplicationTask_603114; body: JsonNode): Recallable =
  ## createReplicationTask
  ## Creates a replication task using the specified parameters.
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var createReplicationTask* = Call_CreateReplicationTask_603114(
    name: "createReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask",
    validator: validate_CreateReplicationTask_603115, base: "/",
    url: url_CreateReplicationTask_603116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificate_603129 = ref object of OpenApiRestCall_602433
proc url_DeleteCertificate_603131(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCertificate_603130(path: JsonNode; query: JsonNode;
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
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603134 = header.getOrDefault("X-Amz-Target")
  valid_603134 = validateParameter(valid_603134, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteCertificate"))
  if valid_603134 != nil:
    section.add "X-Amz-Target", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_DeleteCertificate_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified certificate. 
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_DeleteCertificate_603129; body: JsonNode): Recallable =
  ## deleteCertificate
  ## Deletes the specified certificate. 
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var deleteCertificate* = Call_DeleteCertificate_603129(name: "deleteCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate",
    validator: validate_DeleteCertificate_603130, base: "/",
    url: url_DeleteCertificate_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_603144 = ref object of OpenApiRestCall_602433
proc url_DeleteEndpoint_603146(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEndpoint_603145(path: JsonNode; query: JsonNode;
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
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603149 = header.getOrDefault("X-Amz-Target")
  valid_603149 = validateParameter(valid_603149, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEndpoint"))
  if valid_603149 != nil:
    section.add "X-Amz-Target", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_DeleteEndpoint_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_DeleteEndpoint_603144; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var deleteEndpoint* = Call_DeleteEndpoint_603144(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint",
    validator: validate_DeleteEndpoint_603145, base: "/", url: url_DeleteEndpoint_603146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSubscription_603159 = ref object of OpenApiRestCall_602433
proc url_DeleteEventSubscription_603161(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEventSubscription_603160(path: JsonNode; query: JsonNode;
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
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603164 = header.getOrDefault("X-Amz-Target")
  valid_603164 = validateParameter(valid_603164, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEventSubscription"))
  if valid_603164 != nil:
    section.add "X-Amz-Target", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Content-Sha256", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Algorithm")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Algorithm", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Signature")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Signature", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-SignedHeaders", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Credential")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Credential", valid_603169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_DeleteEventSubscription_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an AWS DMS event subscription. 
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_DeleteEventSubscription_603159; body: JsonNode): Recallable =
  ## deleteEventSubscription
  ##  Deletes an AWS DMS event subscription. 
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var deleteEventSubscription* = Call_DeleteEventSubscription_603159(
    name: "deleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription",
    validator: validate_DeleteEventSubscription_603160, base: "/",
    url: url_DeleteEventSubscription_603161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationInstance_603174 = ref object of OpenApiRestCall_602433
proc url_DeleteReplicationInstance_603176(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationInstance_603175(path: JsonNode; query: JsonNode;
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
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603179 = header.getOrDefault("X-Amz-Target")
  valid_603179 = validateParameter(valid_603179, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationInstance"))
  if valid_603179 != nil:
    section.add "X-Amz-Target", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Content-Sha256", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Algorithm")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Algorithm", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Signature")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Signature", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Credential")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Credential", valid_603184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603186: Call_DeleteReplicationInstance_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_DeleteReplicationInstance_603174; body: JsonNode): Recallable =
  ## deleteReplicationInstance
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var deleteReplicationInstance* = Call_DeleteReplicationInstance_603174(
    name: "deleteReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance",
    validator: validate_DeleteReplicationInstance_603175, base: "/",
    url: url_DeleteReplicationInstance_603176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationSubnetGroup_603189 = ref object of OpenApiRestCall_602433
proc url_DeleteReplicationSubnetGroup_603191(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationSubnetGroup_603190(path: JsonNode; query: JsonNode;
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603194 = header.getOrDefault("X-Amz-Target")
  valid_603194 = validateParameter(valid_603194, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationSubnetGroup"))
  if valid_603194 != nil:
    section.add "X-Amz-Target", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Content-Sha256", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Algorithm", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Credential")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Credential", valid_603199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_DeleteReplicationSubnetGroup_603189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subnet group.
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_DeleteReplicationSubnetGroup_603189; body: JsonNode): Recallable =
  ## deleteReplicationSubnetGroup
  ## Deletes a subnet group.
  ##   body: JObject (required)
  var body_603203 = newJObject()
  if body != nil:
    body_603203 = body
  result = call_603202.call(nil, nil, nil, nil, body_603203)

var deleteReplicationSubnetGroup* = Call_DeleteReplicationSubnetGroup_603189(
    name: "deleteReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup",
    validator: validate_DeleteReplicationSubnetGroup_603190, base: "/",
    url: url_DeleteReplicationSubnetGroup_603191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationTask_603204 = ref object of OpenApiRestCall_602433
proc url_DeleteReplicationTask_603206(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationTask_603205(path: JsonNode; query: JsonNode;
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
  var valid_603207 = header.getOrDefault("X-Amz-Date")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Date", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603209 = header.getOrDefault("X-Amz-Target")
  valid_603209 = validateParameter(valid_603209, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationTask"))
  if valid_603209 != nil:
    section.add "X-Amz-Target", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603216: Call_DeleteReplicationTask_603204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified replication task.
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_DeleteReplicationTask_603204; body: JsonNode): Recallable =
  ## deleteReplicationTask
  ## Deletes the specified replication task.
  ##   body: JObject (required)
  var body_603218 = newJObject()
  if body != nil:
    body_603218 = body
  result = call_603217.call(nil, nil, nil, nil, body_603218)

var deleteReplicationTask* = Call_DeleteReplicationTask_603204(
    name: "deleteReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask",
    validator: validate_DeleteReplicationTask_603205, base: "/",
    url: url_DeleteReplicationTask_603206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_603219 = ref object of OpenApiRestCall_602433
proc url_DescribeAccountAttributes_603221(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAccountAttributes_603220(path: JsonNode; query: JsonNode;
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
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603224 = header.getOrDefault("X-Amz-Target")
  valid_603224 = validateParameter(valid_603224, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeAccountAttributes"))
  if valid_603224 != nil:
    section.add "X-Amz-Target", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Content-Sha256", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Algorithm")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Algorithm", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Signature")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Signature", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-SignedHeaders", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Credential")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Credential", valid_603229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_DescribeAccountAttributes_603219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_DescribeAccountAttributes_603219; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ##   body: JObject (required)
  var body_603233 = newJObject()
  if body != nil:
    body_603233 = body
  result = call_603232.call(nil, nil, nil, nil, body_603233)

var describeAccountAttributes* = Call_DescribeAccountAttributes_603219(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_603220, base: "/",
    url: url_DescribeAccountAttributes_603221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificates_603234 = ref object of OpenApiRestCall_602433
proc url_DescribeCertificates_603236(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCertificates_603235(path: JsonNode; query: JsonNode;
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
  var valid_603237 = query.getOrDefault("MaxRecords")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "MaxRecords", valid_603237
  var valid_603238 = query.getOrDefault("Marker")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "Marker", valid_603238
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
  var valid_603239 = header.getOrDefault("X-Amz-Date")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Date", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Security-Token")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Security-Token", valid_603240
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603241 = header.getOrDefault("X-Amz-Target")
  valid_603241 = validateParameter(valid_603241, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeCertificates"))
  if valid_603241 != nil:
    section.add "X-Amz-Target", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Content-Sha256", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Algorithm")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Algorithm", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Signature")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Signature", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-SignedHeaders", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Credential")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Credential", valid_603246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603248: Call_DescribeCertificates_603234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a description of the certificate.
  ## 
  let valid = call_603248.validator(path, query, header, formData, body)
  let scheme = call_603248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603248.url(scheme.get, call_603248.host, call_603248.base,
                         call_603248.route, valid.getOrDefault("path"))
  result = hook(call_603248, url, valid)

proc call*(call_603249: Call_DescribeCertificates_603234; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeCertificates
  ## Provides a description of the certificate.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603250 = newJObject()
  var body_603251 = newJObject()
  add(query_603250, "MaxRecords", newJString(MaxRecords))
  add(query_603250, "Marker", newJString(Marker))
  if body != nil:
    body_603251 = body
  result = call_603249.call(nil, query_603250, nil, nil, body_603251)

var describeCertificates* = Call_DescribeCertificates_603234(
    name: "describeCertificates", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates",
    validator: validate_DescribeCertificates_603235, base: "/",
    url: url_DescribeCertificates_603236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_603253 = ref object of OpenApiRestCall_602433
proc url_DescribeConnections_603255(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeConnections_603254(path: JsonNode; query: JsonNode;
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
  var valid_603256 = query.getOrDefault("MaxRecords")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "MaxRecords", valid_603256
  var valid_603257 = query.getOrDefault("Marker")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "Marker", valid_603257
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
  var valid_603258 = header.getOrDefault("X-Amz-Date")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Date", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Security-Token")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Security-Token", valid_603259
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603260 = header.getOrDefault("X-Amz-Target")
  valid_603260 = validateParameter(valid_603260, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeConnections"))
  if valid_603260 != nil:
    section.add "X-Amz-Target", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Content-Sha256", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Algorithm")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Algorithm", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Signature")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Signature", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-SignedHeaders", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Credential")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Credential", valid_603265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603267: Call_DescribeConnections_603253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ## 
  let valid = call_603267.validator(path, query, header, formData, body)
  let scheme = call_603267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603267.url(scheme.get, call_603267.host, call_603267.base,
                         call_603267.route, valid.getOrDefault("path"))
  result = hook(call_603267, url, valid)

proc call*(call_603268: Call_DescribeConnections_603253; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeConnections
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603269 = newJObject()
  var body_603270 = newJObject()
  add(query_603269, "MaxRecords", newJString(MaxRecords))
  add(query_603269, "Marker", newJString(Marker))
  if body != nil:
    body_603270 = body
  result = call_603268.call(nil, query_603269, nil, nil, body_603270)

var describeConnections* = Call_DescribeConnections_603253(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeConnections",
    validator: validate_DescribeConnections_603254, base: "/",
    url: url_DescribeConnections_603255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointTypes_603271 = ref object of OpenApiRestCall_602433
proc url_DescribeEndpointTypes_603273(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpointTypes_603272(path: JsonNode; query: JsonNode;
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
  var valid_603274 = query.getOrDefault("MaxRecords")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "MaxRecords", valid_603274
  var valid_603275 = query.getOrDefault("Marker")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "Marker", valid_603275
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
  var valid_603276 = header.getOrDefault("X-Amz-Date")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Date", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Security-Token")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Security-Token", valid_603277
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603278 = header.getOrDefault("X-Amz-Target")
  valid_603278 = validateParameter(valid_603278, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpointTypes"))
  if valid_603278 != nil:
    section.add "X-Amz-Target", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Content-Sha256", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Algorithm")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Algorithm", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Signature")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Signature", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-SignedHeaders", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Credential")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Credential", valid_603283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603285: Call_DescribeEndpointTypes_603271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the type of endpoints available.
  ## 
  let valid = call_603285.validator(path, query, header, formData, body)
  let scheme = call_603285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603285.url(scheme.get, call_603285.host, call_603285.base,
                         call_603285.route, valid.getOrDefault("path"))
  result = hook(call_603285, url, valid)

proc call*(call_603286: Call_DescribeEndpointTypes_603271; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpointTypes
  ## Returns information about the type of endpoints available.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603287 = newJObject()
  var body_603288 = newJObject()
  add(query_603287, "MaxRecords", newJString(MaxRecords))
  add(query_603287, "Marker", newJString(Marker))
  if body != nil:
    body_603288 = body
  result = call_603286.call(nil, query_603287, nil, nil, body_603288)

var describeEndpointTypes* = Call_DescribeEndpointTypes_603271(
    name: "describeEndpointTypes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes",
    validator: validate_DescribeEndpointTypes_603272, base: "/",
    url: url_DescribeEndpointTypes_603273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_603289 = ref object of OpenApiRestCall_602433
proc url_DescribeEndpoints_603291(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpoints_603290(path: JsonNode; query: JsonNode;
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
  var valid_603292 = query.getOrDefault("MaxRecords")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "MaxRecords", valid_603292
  var valid_603293 = query.getOrDefault("Marker")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "Marker", valid_603293
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
  var valid_603294 = header.getOrDefault("X-Amz-Date")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Date", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Security-Token")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Security-Token", valid_603295
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603296 = header.getOrDefault("X-Amz-Target")
  valid_603296 = validateParameter(valid_603296, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpoints"))
  if valid_603296 != nil:
    section.add "X-Amz-Target", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Content-Sha256", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Algorithm")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Algorithm", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Signature")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Signature", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-SignedHeaders", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Credential")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Credential", valid_603301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603303: Call_DescribeEndpoints_603289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the endpoints for your account in the current region.
  ## 
  let valid = call_603303.validator(path, query, header, formData, body)
  let scheme = call_603303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603303.url(scheme.get, call_603303.host, call_603303.base,
                         call_603303.route, valid.getOrDefault("path"))
  result = hook(call_603303, url, valid)

proc call*(call_603304: Call_DescribeEndpoints_603289; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpoints
  ## Returns information about the endpoints for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603305 = newJObject()
  var body_603306 = newJObject()
  add(query_603305, "MaxRecords", newJString(MaxRecords))
  add(query_603305, "Marker", newJString(Marker))
  if body != nil:
    body_603306 = body
  result = call_603304.call(nil, query_603305, nil, nil, body_603306)

var describeEndpoints* = Call_DescribeEndpoints_603289(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints",
    validator: validate_DescribeEndpoints_603290, base: "/",
    url: url_DescribeEndpoints_603291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventCategories_603307 = ref object of OpenApiRestCall_602433
proc url_DescribeEventCategories_603309(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEventCategories_603308(path: JsonNode; query: JsonNode;
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
  var valid_603310 = header.getOrDefault("X-Amz-Date")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Date", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Security-Token")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Security-Token", valid_603311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603312 = header.getOrDefault("X-Amz-Target")
  valid_603312 = validateParameter(valid_603312, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventCategories"))
  if valid_603312 != nil:
    section.add "X-Amz-Target", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Content-Sha256", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Algorithm")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Algorithm", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Signature")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Signature", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-SignedHeaders", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Credential")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Credential", valid_603317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603319: Call_DescribeEventCategories_603307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ## 
  let valid = call_603319.validator(path, query, header, formData, body)
  let scheme = call_603319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603319.url(scheme.get, call_603319.host, call_603319.base,
                         call_603319.route, valid.getOrDefault("path"))
  result = hook(call_603319, url, valid)

proc call*(call_603320: Call_DescribeEventCategories_603307; body: JsonNode): Recallable =
  ## describeEventCategories
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ##   body: JObject (required)
  var body_603321 = newJObject()
  if body != nil:
    body_603321 = body
  result = call_603320.call(nil, nil, nil, nil, body_603321)

var describeEventCategories* = Call_DescribeEventCategories_603307(
    name: "describeEventCategories", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories",
    validator: validate_DescribeEventCategories_603308, base: "/",
    url: url_DescribeEventCategories_603309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventSubscriptions_603322 = ref object of OpenApiRestCall_602433
proc url_DescribeEventSubscriptions_603324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEventSubscriptions_603323(path: JsonNode; query: JsonNode;
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
  var valid_603325 = query.getOrDefault("MaxRecords")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "MaxRecords", valid_603325
  var valid_603326 = query.getOrDefault("Marker")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "Marker", valid_603326
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
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Security-Token")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Security-Token", valid_603328
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603329 = header.getOrDefault("X-Amz-Target")
  valid_603329 = validateParameter(valid_603329, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventSubscriptions"))
  if valid_603329 != nil:
    section.add "X-Amz-Target", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Content-Sha256", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Algorithm")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Algorithm", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Signature")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Signature", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-SignedHeaders", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Credential")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Credential", valid_603334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603336: Call_DescribeEventSubscriptions_603322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ## 
  let valid = call_603336.validator(path, query, header, formData, body)
  let scheme = call_603336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603336.url(scheme.get, call_603336.host, call_603336.base,
                         call_603336.route, valid.getOrDefault("path"))
  result = hook(call_603336, url, valid)

proc call*(call_603337: Call_DescribeEventSubscriptions_603322; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEventSubscriptions
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603338 = newJObject()
  var body_603339 = newJObject()
  add(query_603338, "MaxRecords", newJString(MaxRecords))
  add(query_603338, "Marker", newJString(Marker))
  if body != nil:
    body_603339 = body
  result = call_603337.call(nil, query_603338, nil, nil, body_603339)

var describeEventSubscriptions* = Call_DescribeEventSubscriptions_603322(
    name: "describeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions",
    validator: validate_DescribeEventSubscriptions_603323, base: "/",
    url: url_DescribeEventSubscriptions_603324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_603340 = ref object of OpenApiRestCall_602433
proc url_DescribeEvents_603342(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEvents_603341(path: JsonNode; query: JsonNode;
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
  var valid_603343 = query.getOrDefault("MaxRecords")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "MaxRecords", valid_603343
  var valid_603344 = query.getOrDefault("Marker")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "Marker", valid_603344
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEvents"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_DescribeEvents_603340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_DescribeEvents_603340; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEvents
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603356 = newJObject()
  var body_603357 = newJObject()
  add(query_603356, "MaxRecords", newJString(MaxRecords))
  add(query_603356, "Marker", newJString(Marker))
  if body != nil:
    body_603357 = body
  result = call_603355.call(nil, query_603356, nil, nil, body_603357)

var describeEvents* = Call_DescribeEvents_603340(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEvents",
    validator: validate_DescribeEvents_603341, base: "/", url: url_DescribeEvents_603342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrderableReplicationInstances_603358 = ref object of OpenApiRestCall_602433
proc url_DescribeOrderableReplicationInstances_603360(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeOrderableReplicationInstances_603359(path: JsonNode;
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
  var valid_603361 = query.getOrDefault("MaxRecords")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "MaxRecords", valid_603361
  var valid_603362 = query.getOrDefault("Marker")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "Marker", valid_603362
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
  var valid_603363 = header.getOrDefault("X-Amz-Date")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Date", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Security-Token")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Security-Token", valid_603364
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603365 = header.getOrDefault("X-Amz-Target")
  valid_603365 = validateParameter(valid_603365, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeOrderableReplicationInstances"))
  if valid_603365 != nil:
    section.add "X-Amz-Target", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Algorithm")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Algorithm", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603372: Call_DescribeOrderableReplicationInstances_603358;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication instance types that can be created in the specified region.
  ## 
  let valid = call_603372.validator(path, query, header, formData, body)
  let scheme = call_603372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603372.url(scheme.get, call_603372.host, call_603372.base,
                         call_603372.route, valid.getOrDefault("path"))
  result = hook(call_603372, url, valid)

proc call*(call_603373: Call_DescribeOrderableReplicationInstances_603358;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeOrderableReplicationInstances
  ## Returns information about the replication instance types that can be created in the specified region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603374 = newJObject()
  var body_603375 = newJObject()
  add(query_603374, "MaxRecords", newJString(MaxRecords))
  add(query_603374, "Marker", newJString(Marker))
  if body != nil:
    body_603375 = body
  result = call_603373.call(nil, query_603374, nil, nil, body_603375)

var describeOrderableReplicationInstances* = Call_DescribeOrderableReplicationInstances_603358(
    name: "describeOrderableReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances",
    validator: validate_DescribeOrderableReplicationInstances_603359, base: "/",
    url: url_DescribeOrderableReplicationInstances_603360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingMaintenanceActions_603376 = ref object of OpenApiRestCall_602433
proc url_DescribePendingMaintenanceActions_603378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePendingMaintenanceActions_603377(path: JsonNode;
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
  var valid_603379 = query.getOrDefault("MaxRecords")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "MaxRecords", valid_603379
  var valid_603380 = query.getOrDefault("Marker")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "Marker", valid_603380
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
  var valid_603381 = header.getOrDefault("X-Amz-Date")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Date", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Security-Token")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Security-Token", valid_603382
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603383 = header.getOrDefault("X-Amz-Target")
  valid_603383 = validateParameter(valid_603383, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribePendingMaintenanceActions"))
  if valid_603383 != nil:
    section.add "X-Amz-Target", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Content-Sha256", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Algorithm")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Algorithm", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Signature")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Signature", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-SignedHeaders", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Credential")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Credential", valid_603388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603390: Call_DescribePendingMaintenanceActions_603376;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For internal use only
  ## 
  let valid = call_603390.validator(path, query, header, formData, body)
  let scheme = call_603390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603390.url(scheme.get, call_603390.host, call_603390.base,
                         call_603390.route, valid.getOrDefault("path"))
  result = hook(call_603390, url, valid)

proc call*(call_603391: Call_DescribePendingMaintenanceActions_603376;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describePendingMaintenanceActions
  ## For internal use only
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603392 = newJObject()
  var body_603393 = newJObject()
  add(query_603392, "MaxRecords", newJString(MaxRecords))
  add(query_603392, "Marker", newJString(Marker))
  if body != nil:
    body_603393 = body
  result = call_603391.call(nil, query_603392, nil, nil, body_603393)

var describePendingMaintenanceActions* = Call_DescribePendingMaintenanceActions_603376(
    name: "describePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions",
    validator: validate_DescribePendingMaintenanceActions_603377, base: "/",
    url: url_DescribePendingMaintenanceActions_603378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRefreshSchemasStatus_603394 = ref object of OpenApiRestCall_602433
proc url_DescribeRefreshSchemasStatus_603396(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRefreshSchemasStatus_603395(path: JsonNode; query: JsonNode;
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
  var valid_603397 = header.getOrDefault("X-Amz-Date")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Date", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Security-Token")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Security-Token", valid_603398
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603399 = header.getOrDefault("X-Amz-Target")
  valid_603399 = validateParameter(valid_603399, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeRefreshSchemasStatus"))
  if valid_603399 != nil:
    section.add "X-Amz-Target", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Content-Sha256", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Algorithm")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Algorithm", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Signature")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Signature", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-SignedHeaders", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Credential")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Credential", valid_603404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603406: Call_DescribeRefreshSchemasStatus_603394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of the RefreshSchemas operation.
  ## 
  let valid = call_603406.validator(path, query, header, formData, body)
  let scheme = call_603406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603406.url(scheme.get, call_603406.host, call_603406.base,
                         call_603406.route, valid.getOrDefault("path"))
  result = hook(call_603406, url, valid)

proc call*(call_603407: Call_DescribeRefreshSchemasStatus_603394; body: JsonNode): Recallable =
  ## describeRefreshSchemasStatus
  ## Returns the status of the RefreshSchemas operation.
  ##   body: JObject (required)
  var body_603408 = newJObject()
  if body != nil:
    body_603408 = body
  result = call_603407.call(nil, nil, nil, nil, body_603408)

var describeRefreshSchemasStatus* = Call_DescribeRefreshSchemasStatus_603394(
    name: "describeRefreshSchemasStatus", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus",
    validator: validate_DescribeRefreshSchemasStatus_603395, base: "/",
    url: url_DescribeRefreshSchemasStatus_603396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstanceTaskLogs_603409 = ref object of OpenApiRestCall_602433
proc url_DescribeReplicationInstanceTaskLogs_603411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationInstanceTaskLogs_603410(path: JsonNode;
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
  var valid_603412 = query.getOrDefault("MaxRecords")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "MaxRecords", valid_603412
  var valid_603413 = query.getOrDefault("Marker")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "Marker", valid_603413
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
  var valid_603414 = header.getOrDefault("X-Amz-Date")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Date", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Security-Token")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Security-Token", valid_603415
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603416 = header.getOrDefault("X-Amz-Target")
  valid_603416 = validateParameter(valid_603416, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"))
  if valid_603416 != nil:
    section.add "X-Amz-Target", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Content-Sha256", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Algorithm")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Algorithm", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Signature")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Signature", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-SignedHeaders", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Credential")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Credential", valid_603421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603423: Call_DescribeReplicationInstanceTaskLogs_603409;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the task logs for the specified task.
  ## 
  let valid = call_603423.validator(path, query, header, formData, body)
  let scheme = call_603423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603423.url(scheme.get, call_603423.host, call_603423.base,
                         call_603423.route, valid.getOrDefault("path"))
  result = hook(call_603423, url, valid)

proc call*(call_603424: Call_DescribeReplicationInstanceTaskLogs_603409;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstanceTaskLogs
  ## Returns information about the task logs for the specified task.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603425 = newJObject()
  var body_603426 = newJObject()
  add(query_603425, "MaxRecords", newJString(MaxRecords))
  add(query_603425, "Marker", newJString(Marker))
  if body != nil:
    body_603426 = body
  result = call_603424.call(nil, query_603425, nil, nil, body_603426)

var describeReplicationInstanceTaskLogs* = Call_DescribeReplicationInstanceTaskLogs_603409(
    name: "describeReplicationInstanceTaskLogs", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs",
    validator: validate_DescribeReplicationInstanceTaskLogs_603410, base: "/",
    url: url_DescribeReplicationInstanceTaskLogs_603411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstances_603427 = ref object of OpenApiRestCall_602433
proc url_DescribeReplicationInstances_603429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationInstances_603428(path: JsonNode; query: JsonNode;
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
  var valid_603430 = query.getOrDefault("MaxRecords")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "MaxRecords", valid_603430
  var valid_603431 = query.getOrDefault("Marker")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "Marker", valid_603431
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
  var valid_603432 = header.getOrDefault("X-Amz-Date")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Date", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Security-Token")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Security-Token", valid_603433
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603434 = header.getOrDefault("X-Amz-Target")
  valid_603434 = validateParameter(valid_603434, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstances"))
  if valid_603434 != nil:
    section.add "X-Amz-Target", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Content-Sha256", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Algorithm")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Algorithm", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Signature")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Signature", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-SignedHeaders", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Credential")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Credential", valid_603439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603441: Call_DescribeReplicationInstances_603427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication instances for your account in the current region.
  ## 
  let valid = call_603441.validator(path, query, header, formData, body)
  let scheme = call_603441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603441.url(scheme.get, call_603441.host, call_603441.base,
                         call_603441.route, valid.getOrDefault("path"))
  result = hook(call_603441, url, valid)

proc call*(call_603442: Call_DescribeReplicationInstances_603427; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstances
  ## Returns information about replication instances for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603443 = newJObject()
  var body_603444 = newJObject()
  add(query_603443, "MaxRecords", newJString(MaxRecords))
  add(query_603443, "Marker", newJString(Marker))
  if body != nil:
    body_603444 = body
  result = call_603442.call(nil, query_603443, nil, nil, body_603444)

var describeReplicationInstances* = Call_DescribeReplicationInstances_603427(
    name: "describeReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances",
    validator: validate_DescribeReplicationInstances_603428, base: "/",
    url: url_DescribeReplicationInstances_603429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationSubnetGroups_603445 = ref object of OpenApiRestCall_602433
proc url_DescribeReplicationSubnetGroups_603447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationSubnetGroups_603446(path: JsonNode;
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
  var valid_603448 = query.getOrDefault("MaxRecords")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "MaxRecords", valid_603448
  var valid_603449 = query.getOrDefault("Marker")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "Marker", valid_603449
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
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603452 = header.getOrDefault("X-Amz-Target")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationSubnetGroups"))
  if valid_603452 != nil:
    section.add "X-Amz-Target", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603459: Call_DescribeReplicationSubnetGroups_603445;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication subnet groups.
  ## 
  let valid = call_603459.validator(path, query, header, formData, body)
  let scheme = call_603459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603459.url(scheme.get, call_603459.host, call_603459.base,
                         call_603459.route, valid.getOrDefault("path"))
  result = hook(call_603459, url, valid)

proc call*(call_603460: Call_DescribeReplicationSubnetGroups_603445;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationSubnetGroups
  ## Returns information about the replication subnet groups.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603461 = newJObject()
  var body_603462 = newJObject()
  add(query_603461, "MaxRecords", newJString(MaxRecords))
  add(query_603461, "Marker", newJString(Marker))
  if body != nil:
    body_603462 = body
  result = call_603460.call(nil, query_603461, nil, nil, body_603462)

var describeReplicationSubnetGroups* = Call_DescribeReplicationSubnetGroups_603445(
    name: "describeReplicationSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups",
    validator: validate_DescribeReplicationSubnetGroups_603446, base: "/",
    url: url_DescribeReplicationSubnetGroups_603447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTaskAssessmentResults_603463 = ref object of OpenApiRestCall_602433
proc url_DescribeReplicationTaskAssessmentResults_603465(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationTaskAssessmentResults_603464(path: JsonNode;
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
  var valid_603466 = query.getOrDefault("MaxRecords")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "MaxRecords", valid_603466
  var valid_603467 = query.getOrDefault("Marker")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "Marker", valid_603467
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
  var valid_603468 = header.getOrDefault("X-Amz-Date")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Date", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Security-Token")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Security-Token", valid_603469
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603470 = header.getOrDefault("X-Amz-Target")
  valid_603470 = validateParameter(valid_603470, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"))
  if valid_603470 != nil:
    section.add "X-Amz-Target", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Content-Sha256", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Algorithm")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Algorithm", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Signature")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Signature", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-SignedHeaders", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Credential")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Credential", valid_603475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603477: Call_DescribeReplicationTaskAssessmentResults_603463;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ## 
  let valid = call_603477.validator(path, query, header, formData, body)
  let scheme = call_603477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603477.url(scheme.get, call_603477.host, call_603477.base,
                         call_603477.route, valid.getOrDefault("path"))
  result = hook(call_603477, url, valid)

proc call*(call_603478: Call_DescribeReplicationTaskAssessmentResults_603463;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTaskAssessmentResults
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603479 = newJObject()
  var body_603480 = newJObject()
  add(query_603479, "MaxRecords", newJString(MaxRecords))
  add(query_603479, "Marker", newJString(Marker))
  if body != nil:
    body_603480 = body
  result = call_603478.call(nil, query_603479, nil, nil, body_603480)

var describeReplicationTaskAssessmentResults* = Call_DescribeReplicationTaskAssessmentResults_603463(
    name: "describeReplicationTaskAssessmentResults", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults",
    validator: validate_DescribeReplicationTaskAssessmentResults_603464,
    base: "/", url: url_DescribeReplicationTaskAssessmentResults_603465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTasks_603481 = ref object of OpenApiRestCall_602433
proc url_DescribeReplicationTasks_603483(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationTasks_603482(path: JsonNode; query: JsonNode;
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
  var valid_603484 = query.getOrDefault("MaxRecords")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "MaxRecords", valid_603484
  var valid_603485 = query.getOrDefault("Marker")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "Marker", valid_603485
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
  var valid_603486 = header.getOrDefault("X-Amz-Date")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Date", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Security-Token")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Security-Token", valid_603487
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603488 = header.getOrDefault("X-Amz-Target")
  valid_603488 = validateParameter(valid_603488, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTasks"))
  if valid_603488 != nil:
    section.add "X-Amz-Target", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Content-Sha256", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Algorithm")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Algorithm", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Signature")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Signature", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-SignedHeaders", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Credential")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Credential", valid_603493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603495: Call_DescribeReplicationTasks_603481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication tasks for your account in the current region.
  ## 
  let valid = call_603495.validator(path, query, header, formData, body)
  let scheme = call_603495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603495.url(scheme.get, call_603495.host, call_603495.base,
                         call_603495.route, valid.getOrDefault("path"))
  result = hook(call_603495, url, valid)

proc call*(call_603496: Call_DescribeReplicationTasks_603481; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTasks
  ## Returns information about replication tasks for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603497 = newJObject()
  var body_603498 = newJObject()
  add(query_603497, "MaxRecords", newJString(MaxRecords))
  add(query_603497, "Marker", newJString(Marker))
  if body != nil:
    body_603498 = body
  result = call_603496.call(nil, query_603497, nil, nil, body_603498)

var describeReplicationTasks* = Call_DescribeReplicationTasks_603481(
    name: "describeReplicationTasks", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks",
    validator: validate_DescribeReplicationTasks_603482, base: "/",
    url: url_DescribeReplicationTasks_603483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchemas_603499 = ref object of OpenApiRestCall_602433
proc url_DescribeSchemas_603501(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSchemas_603500(path: JsonNode; query: JsonNode;
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
  var valid_603502 = query.getOrDefault("MaxRecords")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "MaxRecords", valid_603502
  var valid_603503 = query.getOrDefault("Marker")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "Marker", valid_603503
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
  var valid_603504 = header.getOrDefault("X-Amz-Date")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Date", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Security-Token")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Security-Token", valid_603505
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603506 = header.getOrDefault("X-Amz-Target")
  valid_603506 = validateParameter(valid_603506, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeSchemas"))
  if valid_603506 != nil:
    section.add "X-Amz-Target", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Content-Sha256", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Algorithm")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Algorithm", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Signature")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Signature", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-SignedHeaders", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Credential")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Credential", valid_603511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603513: Call_DescribeSchemas_603499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ## 
  let valid = call_603513.validator(path, query, header, formData, body)
  let scheme = call_603513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603513.url(scheme.get, call_603513.host, call_603513.base,
                         call_603513.route, valid.getOrDefault("path"))
  result = hook(call_603513, url, valid)

proc call*(call_603514: Call_DescribeSchemas_603499; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeSchemas
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603515 = newJObject()
  var body_603516 = newJObject()
  add(query_603515, "MaxRecords", newJString(MaxRecords))
  add(query_603515, "Marker", newJString(Marker))
  if body != nil:
    body_603516 = body
  result = call_603514.call(nil, query_603515, nil, nil, body_603516)

var describeSchemas* = Call_DescribeSchemas_603499(name: "describeSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas",
    validator: validate_DescribeSchemas_603500, base: "/", url: url_DescribeSchemas_603501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTableStatistics_603517 = ref object of OpenApiRestCall_602433
proc url_DescribeTableStatistics_603519(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTableStatistics_603518(path: JsonNode; query: JsonNode;
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
  var valid_603520 = query.getOrDefault("MaxRecords")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "MaxRecords", valid_603520
  var valid_603521 = query.getOrDefault("Marker")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "Marker", valid_603521
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
  var valid_603522 = header.getOrDefault("X-Amz-Date")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Date", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Security-Token")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Security-Token", valid_603523
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603524 = header.getOrDefault("X-Amz-Target")
  valid_603524 = validateParameter(valid_603524, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeTableStatistics"))
  if valid_603524 != nil:
    section.add "X-Amz-Target", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Content-Sha256", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Algorithm")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Algorithm", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Signature")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Signature", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-SignedHeaders", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Credential")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Credential", valid_603529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603531: Call_DescribeTableStatistics_603517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ## 
  let valid = call_603531.validator(path, query, header, formData, body)
  let scheme = call_603531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603531.url(scheme.get, call_603531.host, call_603531.base,
                         call_603531.route, valid.getOrDefault("path"))
  result = hook(call_603531, url, valid)

proc call*(call_603532: Call_DescribeTableStatistics_603517; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeTableStatistics
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_603533 = newJObject()
  var body_603534 = newJObject()
  add(query_603533, "MaxRecords", newJString(MaxRecords))
  add(query_603533, "Marker", newJString(Marker))
  if body != nil:
    body_603534 = body
  result = call_603532.call(nil, query_603533, nil, nil, body_603534)

var describeTableStatistics* = Call_DescribeTableStatistics_603517(
    name: "describeTableStatistics", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics",
    validator: validate_DescribeTableStatistics_603518, base: "/",
    url: url_DescribeTableStatistics_603519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificate_603535 = ref object of OpenApiRestCall_602433
proc url_ImportCertificate_603537(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportCertificate_603536(path: JsonNode; query: JsonNode;
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
  var valid_603538 = header.getOrDefault("X-Amz-Date")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Date", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Security-Token")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Security-Token", valid_603539
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603540 = header.getOrDefault("X-Amz-Target")
  valid_603540 = validateParameter(valid_603540, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ImportCertificate"))
  if valid_603540 != nil:
    section.add "X-Amz-Target", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Content-Sha256", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Algorithm")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Algorithm", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Signature")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Signature", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-SignedHeaders", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Credential")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Credential", valid_603545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603547: Call_ImportCertificate_603535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads the specified certificate.
  ## 
  let valid = call_603547.validator(path, query, header, formData, body)
  let scheme = call_603547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603547.url(scheme.get, call_603547.host, call_603547.base,
                         call_603547.route, valid.getOrDefault("path"))
  result = hook(call_603547, url, valid)

proc call*(call_603548: Call_ImportCertificate_603535; body: JsonNode): Recallable =
  ## importCertificate
  ## Uploads the specified certificate.
  ##   body: JObject (required)
  var body_603549 = newJObject()
  if body != nil:
    body_603549 = body
  result = call_603548.call(nil, nil, nil, nil, body_603549)

var importCertificate* = Call_ImportCertificate_603535(name: "importCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ImportCertificate",
    validator: validate_ImportCertificate_603536, base: "/",
    url: url_ImportCertificate_603537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603550 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_603552(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_603551(path: JsonNode; query: JsonNode;
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
  var valid_603553 = header.getOrDefault("X-Amz-Date")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Date", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Security-Token")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Security-Token", valid_603554
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603555 = header.getOrDefault("X-Amz-Target")
  valid_603555 = validateParameter(valid_603555, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ListTagsForResource"))
  if valid_603555 != nil:
    section.add "X-Amz-Target", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Content-Sha256", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Algorithm")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Algorithm", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Signature")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Signature", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-SignedHeaders", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Credential")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Credential", valid_603560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_ListTagsForResource_603550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for an AWS DMS resource.
  ## 
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"))
  result = hook(call_603562, url, valid)

proc call*(call_603563: Call_ListTagsForResource_603550; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags for an AWS DMS resource.
  ##   body: JObject (required)
  var body_603564 = newJObject()
  if body != nil:
    body_603564 = body
  result = call_603563.call(nil, nil, nil, nil, body_603564)

var listTagsForResource* = Call_ListTagsForResource_603550(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource",
    validator: validate_ListTagsForResource_603551, base: "/",
    url: url_ListTagsForResource_603552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEndpoint_603565 = ref object of OpenApiRestCall_602433
proc url_ModifyEndpoint_603567(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyEndpoint_603566(path: JsonNode; query: JsonNode;
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
  var valid_603568 = header.getOrDefault("X-Amz-Date")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Date", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Security-Token")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Security-Token", valid_603569
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603570 = header.getOrDefault("X-Amz-Target")
  valid_603570 = validateParameter(valid_603570, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEndpoint"))
  if valid_603570 != nil:
    section.add "X-Amz-Target", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Content-Sha256", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Algorithm")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Algorithm", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Signature")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Signature", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-SignedHeaders", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Credential")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Credential", valid_603575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603577: Call_ModifyEndpoint_603565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified endpoint.
  ## 
  let valid = call_603577.validator(path, query, header, formData, body)
  let scheme = call_603577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603577.url(scheme.get, call_603577.host, call_603577.base,
                         call_603577.route, valid.getOrDefault("path"))
  result = hook(call_603577, url, valid)

proc call*(call_603578: Call_ModifyEndpoint_603565; body: JsonNode): Recallable =
  ## modifyEndpoint
  ## Modifies the specified endpoint.
  ##   body: JObject (required)
  var body_603579 = newJObject()
  if body != nil:
    body_603579 = body
  result = call_603578.call(nil, nil, nil, nil, body_603579)

var modifyEndpoint* = Call_ModifyEndpoint_603565(name: "modifyEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint",
    validator: validate_ModifyEndpoint_603566, base: "/", url: url_ModifyEndpoint_603567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEventSubscription_603580 = ref object of OpenApiRestCall_602433
proc url_ModifyEventSubscription_603582(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyEventSubscription_603581(path: JsonNode; query: JsonNode;
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
  var valid_603583 = header.getOrDefault("X-Amz-Date")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Date", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Security-Token")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Security-Token", valid_603584
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603585 = header.getOrDefault("X-Amz-Target")
  valid_603585 = validateParameter(valid_603585, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEventSubscription"))
  if valid_603585 != nil:
    section.add "X-Amz-Target", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Algorithm")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Algorithm", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Signature")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Signature", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Credential")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Credential", valid_603590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_ModifyEventSubscription_603580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing AWS DMS event notification subscription. 
  ## 
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_ModifyEventSubscription_603580; body: JsonNode): Recallable =
  ## modifyEventSubscription
  ## Modifies an existing AWS DMS event notification subscription. 
  ##   body: JObject (required)
  var body_603594 = newJObject()
  if body != nil:
    body_603594 = body
  result = call_603593.call(nil, nil, nil, nil, body_603594)

var modifyEventSubscription* = Call_ModifyEventSubscription_603580(
    name: "modifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription",
    validator: validate_ModifyEventSubscription_603581, base: "/",
    url: url_ModifyEventSubscription_603582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationInstance_603595 = ref object of OpenApiRestCall_602433
proc url_ModifyReplicationInstance_603597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReplicationInstance_603596(path: JsonNode; query: JsonNode;
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
  var valid_603598 = header.getOrDefault("X-Amz-Date")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Date", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Security-Token")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Security-Token", valid_603599
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603600 = header.getOrDefault("X-Amz-Target")
  valid_603600 = validateParameter(valid_603600, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationInstance"))
  if valid_603600 != nil:
    section.add "X-Amz-Target", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Algorithm")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Algorithm", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Signature")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Signature", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-SignedHeaders", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Credential")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Credential", valid_603605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603607: Call_ModifyReplicationInstance_603595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ## 
  let valid = call_603607.validator(path, query, header, formData, body)
  let scheme = call_603607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603607.url(scheme.get, call_603607.host, call_603607.base,
                         call_603607.route, valid.getOrDefault("path"))
  result = hook(call_603607, url, valid)

proc call*(call_603608: Call_ModifyReplicationInstance_603595; body: JsonNode): Recallable =
  ## modifyReplicationInstance
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ##   body: JObject (required)
  var body_603609 = newJObject()
  if body != nil:
    body_603609 = body
  result = call_603608.call(nil, nil, nil, nil, body_603609)

var modifyReplicationInstance* = Call_ModifyReplicationInstance_603595(
    name: "modifyReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance",
    validator: validate_ModifyReplicationInstance_603596, base: "/",
    url: url_ModifyReplicationInstance_603597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationSubnetGroup_603610 = ref object of OpenApiRestCall_602433
proc url_ModifyReplicationSubnetGroup_603612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReplicationSubnetGroup_603611(path: JsonNode; query: JsonNode;
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
  var valid_603613 = header.getOrDefault("X-Amz-Date")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Date", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Security-Token")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Security-Token", valid_603614
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603615 = header.getOrDefault("X-Amz-Target")
  valid_603615 = validateParameter(valid_603615, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationSubnetGroup"))
  if valid_603615 != nil:
    section.add "X-Amz-Target", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Content-Sha256", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Algorithm")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Algorithm", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Signature")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Signature", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-SignedHeaders", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Credential")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Credential", valid_603620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_ModifyReplicationSubnetGroup_603610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for the specified replication subnet group.
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"))
  result = hook(call_603622, url, valid)

proc call*(call_603623: Call_ModifyReplicationSubnetGroup_603610; body: JsonNode): Recallable =
  ## modifyReplicationSubnetGroup
  ## Modifies the settings for the specified replication subnet group.
  ##   body: JObject (required)
  var body_603624 = newJObject()
  if body != nil:
    body_603624 = body
  result = call_603623.call(nil, nil, nil, nil, body_603624)

var modifyReplicationSubnetGroup* = Call_ModifyReplicationSubnetGroup_603610(
    name: "modifyReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup",
    validator: validate_ModifyReplicationSubnetGroup_603611, base: "/",
    url: url_ModifyReplicationSubnetGroup_603612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationTask_603625 = ref object of OpenApiRestCall_602433
proc url_ModifyReplicationTask_603627(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReplicationTask_603626(path: JsonNode; query: JsonNode;
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
  var valid_603628 = header.getOrDefault("X-Amz-Date")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Date", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Security-Token")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Security-Token", valid_603629
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603630 = header.getOrDefault("X-Amz-Target")
  valid_603630 = validateParameter(valid_603630, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationTask"))
  if valid_603630 != nil:
    section.add "X-Amz-Target", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Content-Sha256", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Algorithm")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Algorithm", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Signature")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Signature", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-SignedHeaders", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Credential")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Credential", valid_603635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603637: Call_ModifyReplicationTask_603625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ## 
  let valid = call_603637.validator(path, query, header, formData, body)
  let scheme = call_603637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603637.url(scheme.get, call_603637.host, call_603637.base,
                         call_603637.route, valid.getOrDefault("path"))
  result = hook(call_603637, url, valid)

proc call*(call_603638: Call_ModifyReplicationTask_603625; body: JsonNode): Recallable =
  ## modifyReplicationTask
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603639 = newJObject()
  if body != nil:
    body_603639 = body
  result = call_603638.call(nil, nil, nil, nil, body_603639)

var modifyReplicationTask* = Call_ModifyReplicationTask_603625(
    name: "modifyReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask",
    validator: validate_ModifyReplicationTask_603626, base: "/",
    url: url_ModifyReplicationTask_603627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootReplicationInstance_603640 = ref object of OpenApiRestCall_602433
proc url_RebootReplicationInstance_603642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RebootReplicationInstance_603641(path: JsonNode; query: JsonNode;
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
  var valid_603643 = header.getOrDefault("X-Amz-Date")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Date", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Security-Token")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Security-Token", valid_603644
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603645 = header.getOrDefault("X-Amz-Target")
  valid_603645 = validateParameter(valid_603645, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RebootReplicationInstance"))
  if valid_603645 != nil:
    section.add "X-Amz-Target", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Content-Sha256", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Algorithm")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Algorithm", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Signature")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Signature", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-SignedHeaders", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Credential")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Credential", valid_603650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603652: Call_RebootReplicationInstance_603640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ## 
  let valid = call_603652.validator(path, query, header, formData, body)
  let scheme = call_603652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603652.url(scheme.get, call_603652.host, call_603652.base,
                         call_603652.route, valid.getOrDefault("path"))
  result = hook(call_603652, url, valid)

proc call*(call_603653: Call_RebootReplicationInstance_603640; body: JsonNode): Recallable =
  ## rebootReplicationInstance
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ##   body: JObject (required)
  var body_603654 = newJObject()
  if body != nil:
    body_603654 = body
  result = call_603653.call(nil, nil, nil, nil, body_603654)

var rebootReplicationInstance* = Call_RebootReplicationInstance_603640(
    name: "rebootReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance",
    validator: validate_RebootReplicationInstance_603641, base: "/",
    url: url_RebootReplicationInstance_603642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshSchemas_603655 = ref object of OpenApiRestCall_602433
proc url_RefreshSchemas_603657(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RefreshSchemas_603656(path: JsonNode; query: JsonNode;
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
  var valid_603658 = header.getOrDefault("X-Amz-Date")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Date", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Security-Token")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Security-Token", valid_603659
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603660 = header.getOrDefault("X-Amz-Target")
  valid_603660 = validateParameter(valid_603660, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RefreshSchemas"))
  if valid_603660 != nil:
    section.add "X-Amz-Target", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Content-Sha256", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Algorithm")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Algorithm", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Signature")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Signature", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-SignedHeaders", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Credential")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Credential", valid_603665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603667: Call_RefreshSchemas_603655; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ## 
  let valid = call_603667.validator(path, query, header, formData, body)
  let scheme = call_603667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603667.url(scheme.get, call_603667.host, call_603667.base,
                         call_603667.route, valid.getOrDefault("path"))
  result = hook(call_603667, url, valid)

proc call*(call_603668: Call_RefreshSchemas_603655; body: JsonNode): Recallable =
  ## refreshSchemas
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ##   body: JObject (required)
  var body_603669 = newJObject()
  if body != nil:
    body_603669 = body
  result = call_603668.call(nil, nil, nil, nil, body_603669)

var refreshSchemas* = Call_RefreshSchemas_603655(name: "refreshSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas",
    validator: validate_RefreshSchemas_603656, base: "/", url: url_RefreshSchemas_603657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReloadTables_603670 = ref object of OpenApiRestCall_602433
proc url_ReloadTables_603672(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ReloadTables_603671(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603673 = header.getOrDefault("X-Amz-Date")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Date", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Security-Token")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Security-Token", valid_603674
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603675 = header.getOrDefault("X-Amz-Target")
  valid_603675 = validateParameter(valid_603675, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ReloadTables"))
  if valid_603675 != nil:
    section.add "X-Amz-Target", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Content-Sha256", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Algorithm")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Algorithm", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Signature")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Signature", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-SignedHeaders", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Credential")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Credential", valid_603680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603682: Call_ReloadTables_603670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reloads the target database table with the source data. 
  ## 
  let valid = call_603682.validator(path, query, header, formData, body)
  let scheme = call_603682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603682.url(scheme.get, call_603682.host, call_603682.base,
                         call_603682.route, valid.getOrDefault("path"))
  result = hook(call_603682, url, valid)

proc call*(call_603683: Call_ReloadTables_603670; body: JsonNode): Recallable =
  ## reloadTables
  ## Reloads the target database table with the source data. 
  ##   body: JObject (required)
  var body_603684 = newJObject()
  if body != nil:
    body_603684 = body
  result = call_603683.call(nil, nil, nil, nil, body_603684)

var reloadTables* = Call_ReloadTables_603670(name: "reloadTables",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ReloadTables",
    validator: validate_ReloadTables_603671, base: "/", url: url_ReloadTables_603672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_603685 = ref object of OpenApiRestCall_602433
proc url_RemoveTagsFromResource_603687(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTagsFromResource_603686(path: JsonNode; query: JsonNode;
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
  var valid_603688 = header.getOrDefault("X-Amz-Date")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Date", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Security-Token")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Security-Token", valid_603689
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603690 = header.getOrDefault("X-Amz-Target")
  valid_603690 = validateParameter(valid_603690, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RemoveTagsFromResource"))
  if valid_603690 != nil:
    section.add "X-Amz-Target", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Content-Sha256", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Algorithm")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Algorithm", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Signature")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Signature", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-SignedHeaders", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Credential")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Credential", valid_603695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603697: Call_RemoveTagsFromResource_603685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a DMS resource.
  ## 
  let valid = call_603697.validator(path, query, header, formData, body)
  let scheme = call_603697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603697.url(scheme.get, call_603697.host, call_603697.base,
                         call_603697.route, valid.getOrDefault("path"))
  result = hook(call_603697, url, valid)

proc call*(call_603698: Call_RemoveTagsFromResource_603685; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes metadata tags from a DMS resource.
  ##   body: JObject (required)
  var body_603699 = newJObject()
  if body != nil:
    body_603699 = body
  result = call_603698.call(nil, nil, nil, nil, body_603699)

var removeTagsFromResource* = Call_RemoveTagsFromResource_603685(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_603686, base: "/",
    url: url_RemoveTagsFromResource_603687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTask_603700 = ref object of OpenApiRestCall_602433
proc url_StartReplicationTask_603702(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartReplicationTask_603701(path: JsonNode; query: JsonNode;
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
  var valid_603703 = header.getOrDefault("X-Amz-Date")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Date", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Security-Token")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Security-Token", valid_603704
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603705 = header.getOrDefault("X-Amz-Target")
  valid_603705 = validateParameter(valid_603705, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTask"))
  if valid_603705 != nil:
    section.add "X-Amz-Target", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Content-Sha256", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Algorithm")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Algorithm", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Signature")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Signature", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-SignedHeaders", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Credential")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Credential", valid_603710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603712: Call_StartReplicationTask_603700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_603712.validator(path, query, header, formData, body)
  let scheme = call_603712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603712.url(scheme.get, call_603712.host, call_603712.base,
                         call_603712.route, valid.getOrDefault("path"))
  result = hook(call_603712, url, valid)

proc call*(call_603713: Call_StartReplicationTask_603700; body: JsonNode): Recallable =
  ## startReplicationTask
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_603714 = newJObject()
  if body != nil:
    body_603714 = body
  result = call_603713.call(nil, nil, nil, nil, body_603714)

var startReplicationTask* = Call_StartReplicationTask_603700(
    name: "startReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask",
    validator: validate_StartReplicationTask_603701, base: "/",
    url: url_StartReplicationTask_603702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTaskAssessment_603715 = ref object of OpenApiRestCall_602433
proc url_StartReplicationTaskAssessment_603717(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartReplicationTaskAssessment_603716(path: JsonNode;
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
  var valid_603718 = header.getOrDefault("X-Amz-Date")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Date", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Security-Token")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Security-Token", valid_603719
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603720 = header.getOrDefault("X-Amz-Target")
  valid_603720 = validateParameter(valid_603720, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTaskAssessment"))
  if valid_603720 != nil:
    section.add "X-Amz-Target", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Content-Sha256", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Algorithm")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Algorithm", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Signature")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Signature", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-SignedHeaders", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Credential")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Credential", valid_603725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603727: Call_StartReplicationTaskAssessment_603715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ## 
  let valid = call_603727.validator(path, query, header, formData, body)
  let scheme = call_603727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603727.url(scheme.get, call_603727.host, call_603727.base,
                         call_603727.route, valid.getOrDefault("path"))
  result = hook(call_603727, url, valid)

proc call*(call_603728: Call_StartReplicationTaskAssessment_603715; body: JsonNode): Recallable =
  ## startReplicationTaskAssessment
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ##   body: JObject (required)
  var body_603729 = newJObject()
  if body != nil:
    body_603729 = body
  result = call_603728.call(nil, nil, nil, nil, body_603729)

var startReplicationTaskAssessment* = Call_StartReplicationTaskAssessment_603715(
    name: "startReplicationTaskAssessment", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment",
    validator: validate_StartReplicationTaskAssessment_603716, base: "/",
    url: url_StartReplicationTaskAssessment_603717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopReplicationTask_603730 = ref object of OpenApiRestCall_602433
proc url_StopReplicationTask_603732(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopReplicationTask_603731(path: JsonNode; query: JsonNode;
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
  var valid_603733 = header.getOrDefault("X-Amz-Date")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Date", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Security-Token")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Security-Token", valid_603734
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603735 = header.getOrDefault("X-Amz-Target")
  valid_603735 = validateParameter(valid_603735, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StopReplicationTask"))
  if valid_603735 != nil:
    section.add "X-Amz-Target", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Content-Sha256", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Algorithm")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Algorithm", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Signature")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Signature", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-SignedHeaders", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Credential")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Credential", valid_603740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603742: Call_StopReplicationTask_603730; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops the replication task.</p> <p/>
  ## 
  let valid = call_603742.validator(path, query, header, formData, body)
  let scheme = call_603742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603742.url(scheme.get, call_603742.host, call_603742.base,
                         call_603742.route, valid.getOrDefault("path"))
  result = hook(call_603742, url, valid)

proc call*(call_603743: Call_StopReplicationTask_603730; body: JsonNode): Recallable =
  ## stopReplicationTask
  ## <p>Stops the replication task.</p> <p/>
  ##   body: JObject (required)
  var body_603744 = newJObject()
  if body != nil:
    body_603744 = body
  result = call_603743.call(nil, nil, nil, nil, body_603744)

var stopReplicationTask* = Call_StopReplicationTask_603730(
    name: "stopReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask",
    validator: validate_StopReplicationTask_603731, base: "/",
    url: url_StopReplicationTask_603732, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestConnection_603745 = ref object of OpenApiRestCall_602433
proc url_TestConnection_603747(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TestConnection_603746(path: JsonNode; query: JsonNode;
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
  var valid_603748 = header.getOrDefault("X-Amz-Date")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Date", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Security-Token")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Security-Token", valid_603749
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603750 = header.getOrDefault("X-Amz-Target")
  valid_603750 = validateParameter(valid_603750, JString, required = true, default = newJString(
      "AmazonDMSv20160101.TestConnection"))
  if valid_603750 != nil:
    section.add "X-Amz-Target", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Content-Sha256", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Algorithm")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Algorithm", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Signature")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Signature", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-SignedHeaders", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Credential")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Credential", valid_603755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603757: Call_TestConnection_603745; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the connection between the replication instance and the endpoint.
  ## 
  let valid = call_603757.validator(path, query, header, formData, body)
  let scheme = call_603757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603757.url(scheme.get, call_603757.host, call_603757.base,
                         call_603757.route, valid.getOrDefault("path"))
  result = hook(call_603757, url, valid)

proc call*(call_603758: Call_TestConnection_603745; body: JsonNode): Recallable =
  ## testConnection
  ## Tests the connection between the replication instance and the endpoint.
  ##   body: JObject (required)
  var body_603759 = newJObject()
  if body != nil:
    body_603759 = body
  result = call_603758.call(nil, nil, nil, nil, body_603759)

var testConnection* = Call_TestConnection_603745(name: "testConnection",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.TestConnection",
    validator: validate_TestConnection_603746, base: "/", url: url_TestConnection_603747,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
