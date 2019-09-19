
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_AddTagsToResource_772933 = ref object of OpenApiRestCall_772597
proc url_AddTagsToResource_772935(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTagsToResource_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "AmazonDMSv20160101.AddTagsToResource"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_AddTagsToResource_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_AddTagsToResource_772933; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds metadata tags to an AWS DMS resource, including replication instance, endpoint, security group, and migration task. These tags can also be used with cost allocation reporting to track cost associated with DMS resources, or used in a Condition statement in an IAM policy for DMS.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var addTagsToResource* = Call_AddTagsToResource_772933(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.AddTagsToResource",
    validator: validate_AddTagsToResource_772934, base: "/",
    url: url_AddTagsToResource_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ApplyPendingMaintenanceAction_773202 = ref object of OpenApiRestCall_772597
proc url_ApplyPendingMaintenanceAction_773204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ApplyPendingMaintenanceAction_773203(path: JsonNode; query: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ApplyPendingMaintenanceAction"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_ApplyPendingMaintenanceAction_773202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_ApplyPendingMaintenanceAction_773202; body: JsonNode): Recallable =
  ## applyPendingMaintenanceAction
  ## Applies a pending maintenance action to a resource (for example, to a replication instance).
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var applyPendingMaintenanceAction* = Call_ApplyPendingMaintenanceAction_773202(
    name: "applyPendingMaintenanceAction", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ApplyPendingMaintenanceAction",
    validator: validate_ApplyPendingMaintenanceAction_773203, base: "/",
    url: url_ApplyPendingMaintenanceAction_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_773217 = ref object of OpenApiRestCall_772597
proc url_CreateEndpoint_773219(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEndpoint_773218(path: JsonNode; query: JsonNode;
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEndpoint"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_CreateEndpoint_773217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint using the provided settings.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_CreateEndpoint_773217; body: JsonNode): Recallable =
  ## createEndpoint
  ## Creates an endpoint using the provided settings.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var createEndpoint* = Call_CreateEndpoint_773217(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEndpoint",
    validator: validate_CreateEndpoint_773218, base: "/", url: url_CreateEndpoint_773219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSubscription_773232 = ref object of OpenApiRestCall_772597
proc url_CreateEventSubscription_773234(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEventSubscription_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateEventSubscription"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_CreateEventSubscription_773232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_CreateEventSubscription_773232; body: JsonNode): Recallable =
  ## createEventSubscription
  ## <p> Creates an AWS DMS event notification subscription. </p> <p>You can specify the type of source (<code>SourceType</code>) you want to be notified of, provide a list of AWS DMS source IDs (<code>SourceIds</code>) that triggers the events, and provide a list of event categories (<code>EventCategories</code>) for events you want to be notified of. If you specify both the <code>SourceType</code> and <code>SourceIds</code>, such as <code>SourceType = replication-instance</code> and <code>SourceIdentifier = my-replinstance</code>, you will be notified of all the replication instance events for the specified source. If you specify a <code>SourceType</code> but don't specify a <code>SourceIdentifier</code>, you receive notice of the events for that source type for all your AWS DMS sources. If you don't specify either <code>SourceType</code> nor <code>SourceIdentifier</code>, you will be notified of events generated from all AWS DMS sources belonging to your customer account.</p> <p>For more information about AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var createEventSubscription* = Call_CreateEventSubscription_773232(
    name: "createEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateEventSubscription",
    validator: validate_CreateEventSubscription_773233, base: "/",
    url: url_CreateEventSubscription_773234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationInstance_773247 = ref object of OpenApiRestCall_772597
proc url_CreateReplicationInstance_773249(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationInstance_773248(path: JsonNode; query: JsonNode;
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationInstance"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_CreateReplicationInstance_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates the replication instance using the specified parameters.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_CreateReplicationInstance_773247; body: JsonNode): Recallable =
  ## createReplicationInstance
  ## Creates the replication instance using the specified parameters.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var createReplicationInstance* = Call_CreateReplicationInstance_773247(
    name: "createReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationInstance",
    validator: validate_CreateReplicationInstance_773248, base: "/",
    url: url_CreateReplicationInstance_773249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationSubnetGroup_773262 = ref object of OpenApiRestCall_772597
proc url_CreateReplicationSubnetGroup_773264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationSubnetGroup_773263(path: JsonNode; query: JsonNode;
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationSubnetGroup"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_CreateReplicationSubnetGroup_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_CreateReplicationSubnetGroup_773262; body: JsonNode): Recallable =
  ## createReplicationSubnetGroup
  ## Creates a replication subnet group given a list of the subnet IDs in a VPC.
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var createReplicationSubnetGroup* = Call_CreateReplicationSubnetGroup_773262(
    name: "createReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationSubnetGroup",
    validator: validate_CreateReplicationSubnetGroup_773263, base: "/",
    url: url_CreateReplicationSubnetGroup_773264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReplicationTask_773277 = ref object of OpenApiRestCall_772597
proc url_CreateReplicationTask_773279(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateReplicationTask_773278(path: JsonNode; query: JsonNode;
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "AmazonDMSv20160101.CreateReplicationTask"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_CreateReplicationTask_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a replication task using the specified parameters.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_CreateReplicationTask_773277; body: JsonNode): Recallable =
  ## createReplicationTask
  ## Creates a replication task using the specified parameters.
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var createReplicationTask* = Call_CreateReplicationTask_773277(
    name: "createReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.CreateReplicationTask",
    validator: validate_CreateReplicationTask_773278, base: "/",
    url: url_CreateReplicationTask_773279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCertificate_773292 = ref object of OpenApiRestCall_772597
proc url_DeleteCertificate_773294(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCertificate_773293(path: JsonNode; query: JsonNode;
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteCertificate"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_DeleteCertificate_773292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified certificate. 
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_DeleteCertificate_773292; body: JsonNode): Recallable =
  ## deleteCertificate
  ## Deletes the specified certificate. 
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var deleteCertificate* = Call_DeleteCertificate_773292(name: "deleteCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteCertificate",
    validator: validate_DeleteCertificate_773293, base: "/",
    url: url_DeleteCertificate_773294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_773307 = ref object of OpenApiRestCall_772597
proc url_DeleteEndpoint_773309(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEndpoint_773308(path: JsonNode; query: JsonNode;
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
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEndpoint"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_DeleteEndpoint_773307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_DeleteEndpoint_773307; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes the specified endpoint.</p> <note> <p>All tasks associated with the endpoint must be deleted before you can delete the endpoint.</p> </note> <p/>
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var deleteEndpoint* = Call_DeleteEndpoint_773307(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEndpoint",
    validator: validate_DeleteEndpoint_773308, base: "/", url: url_DeleteEndpoint_773309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSubscription_773322 = ref object of OpenApiRestCall_772597
proc url_DeleteEventSubscription_773324(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEventSubscription_773323(path: JsonNode; query: JsonNode;
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteEventSubscription"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_DeleteEventSubscription_773322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Deletes an AWS DMS event subscription. 
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_DeleteEventSubscription_773322; body: JsonNode): Recallable =
  ## deleteEventSubscription
  ##  Deletes an AWS DMS event subscription. 
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var deleteEventSubscription* = Call_DeleteEventSubscription_773322(
    name: "deleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteEventSubscription",
    validator: validate_DeleteEventSubscription_773323, base: "/",
    url: url_DeleteEventSubscription_773324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationInstance_773337 = ref object of OpenApiRestCall_772597
proc url_DeleteReplicationInstance_773339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationInstance_773338(path: JsonNode; query: JsonNode;
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationInstance"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_DeleteReplicationInstance_773337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_DeleteReplicationInstance_773337; body: JsonNode): Recallable =
  ## deleteReplicationInstance
  ## <p>Deletes the specified replication instance.</p> <note> <p>You must delete any migration tasks that are associated with the replication instance before you can delete it.</p> </note> <p/>
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var deleteReplicationInstance* = Call_DeleteReplicationInstance_773337(
    name: "deleteReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationInstance",
    validator: validate_DeleteReplicationInstance_773338, base: "/",
    url: url_DeleteReplicationInstance_773339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationSubnetGroup_773352 = ref object of OpenApiRestCall_772597
proc url_DeleteReplicationSubnetGroup_773354(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationSubnetGroup_773353(path: JsonNode; query: JsonNode;
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
  var valid_773355 = header.getOrDefault("X-Amz-Date")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "X-Amz-Date", valid_773355
  var valid_773356 = header.getOrDefault("X-Amz-Security-Token")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Security-Token", valid_773356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773357 = header.getOrDefault("X-Amz-Target")
  valid_773357 = validateParameter(valid_773357, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationSubnetGroup"))
  if valid_773357 != nil:
    section.add "X-Amz-Target", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773364: Call_DeleteReplicationSubnetGroup_773352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a subnet group.
  ## 
  let valid = call_773364.validator(path, query, header, formData, body)
  let scheme = call_773364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773364.url(scheme.get, call_773364.host, call_773364.base,
                         call_773364.route, valid.getOrDefault("path"))
  result = hook(call_773364, url, valid)

proc call*(call_773365: Call_DeleteReplicationSubnetGroup_773352; body: JsonNode): Recallable =
  ## deleteReplicationSubnetGroup
  ## Deletes a subnet group.
  ##   body: JObject (required)
  var body_773366 = newJObject()
  if body != nil:
    body_773366 = body
  result = call_773365.call(nil, nil, nil, nil, body_773366)

var deleteReplicationSubnetGroup* = Call_DeleteReplicationSubnetGroup_773352(
    name: "deleteReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationSubnetGroup",
    validator: validate_DeleteReplicationSubnetGroup_773353, base: "/",
    url: url_DeleteReplicationSubnetGroup_773354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReplicationTask_773367 = ref object of OpenApiRestCall_772597
proc url_DeleteReplicationTask_773369(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteReplicationTask_773368(path: JsonNode; query: JsonNode;
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
  var valid_773370 = header.getOrDefault("X-Amz-Date")
  valid_773370 = validateParameter(valid_773370, JString, required = false,
                                 default = nil)
  if valid_773370 != nil:
    section.add "X-Amz-Date", valid_773370
  var valid_773371 = header.getOrDefault("X-Amz-Security-Token")
  valid_773371 = validateParameter(valid_773371, JString, required = false,
                                 default = nil)
  if valid_773371 != nil:
    section.add "X-Amz-Security-Token", valid_773371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773372 = header.getOrDefault("X-Amz-Target")
  valid_773372 = validateParameter(valid_773372, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DeleteReplicationTask"))
  if valid_773372 != nil:
    section.add "X-Amz-Target", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Content-Sha256", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Algorithm")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Algorithm", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Signature")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Signature", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-SignedHeaders", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Credential")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Credential", valid_773377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773379: Call_DeleteReplicationTask_773367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified replication task.
  ## 
  let valid = call_773379.validator(path, query, header, formData, body)
  let scheme = call_773379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773379.url(scheme.get, call_773379.host, call_773379.base,
                         call_773379.route, valid.getOrDefault("path"))
  result = hook(call_773379, url, valid)

proc call*(call_773380: Call_DeleteReplicationTask_773367; body: JsonNode): Recallable =
  ## deleteReplicationTask
  ## Deletes the specified replication task.
  ##   body: JObject (required)
  var body_773381 = newJObject()
  if body != nil:
    body_773381 = body
  result = call_773380.call(nil, nil, nil, nil, body_773381)

var deleteReplicationTask* = Call_DeleteReplicationTask_773367(
    name: "deleteReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DeleteReplicationTask",
    validator: validate_DeleteReplicationTask_773368, base: "/",
    url: url_DeleteReplicationTask_773369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAccountAttributes_773382 = ref object of OpenApiRestCall_772597
proc url_DescribeAccountAttributes_773384(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAccountAttributes_773383(path: JsonNode; query: JsonNode;
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
  var valid_773385 = header.getOrDefault("X-Amz-Date")
  valid_773385 = validateParameter(valid_773385, JString, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "X-Amz-Date", valid_773385
  var valid_773386 = header.getOrDefault("X-Amz-Security-Token")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "X-Amz-Security-Token", valid_773386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773387 = header.getOrDefault("X-Amz-Target")
  valid_773387 = validateParameter(valid_773387, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeAccountAttributes"))
  if valid_773387 != nil:
    section.add "X-Amz-Target", valid_773387
  var valid_773388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Content-Sha256", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Algorithm")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Algorithm", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Signature")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Signature", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-SignedHeaders", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Credential")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Credential", valid_773392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773394: Call_DescribeAccountAttributes_773382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ## 
  let valid = call_773394.validator(path, query, header, formData, body)
  let scheme = call_773394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773394.url(scheme.get, call_773394.host, call_773394.base,
                         call_773394.route, valid.getOrDefault("path"))
  result = hook(call_773394, url, valid)

proc call*(call_773395: Call_DescribeAccountAttributes_773382; body: JsonNode): Recallable =
  ## describeAccountAttributes
  ## <p>Lists all of the AWS DMS attributes for a customer account. These attributes include AWS DMS quotas for the account and a unique account identifier in a particular DMS region. DMS quotas include a list of resource quotas supported by the account, such as the number of replication instances allowed. The description for each resource quota, includes the quota name, current usage toward that quota, and the quota's maximum value. DMS uses the unique account identifier to name each artifact used by DMS in the given region.</p> <p>This command does not take any parameters.</p>
  ##   body: JObject (required)
  var body_773396 = newJObject()
  if body != nil:
    body_773396 = body
  result = call_773395.call(nil, nil, nil, nil, body_773396)

var describeAccountAttributes* = Call_DescribeAccountAttributes_773382(
    name: "describeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeAccountAttributes",
    validator: validate_DescribeAccountAttributes_773383, base: "/",
    url: url_DescribeAccountAttributes_773384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificates_773397 = ref object of OpenApiRestCall_772597
proc url_DescribeCertificates_773399(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCertificates_773398(path: JsonNode; query: JsonNode;
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
  var valid_773400 = query.getOrDefault("MaxRecords")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "MaxRecords", valid_773400
  var valid_773401 = query.getOrDefault("Marker")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "Marker", valid_773401
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
  var valid_773402 = header.getOrDefault("X-Amz-Date")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Date", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Security-Token")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Security-Token", valid_773403
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773404 = header.getOrDefault("X-Amz-Target")
  valid_773404 = validateParameter(valid_773404, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeCertificates"))
  if valid_773404 != nil:
    section.add "X-Amz-Target", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Content-Sha256", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-Algorithm")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Algorithm", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Signature")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Signature", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-SignedHeaders", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Credential")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Credential", valid_773409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773411: Call_DescribeCertificates_773397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a description of the certificate.
  ## 
  let valid = call_773411.validator(path, query, header, formData, body)
  let scheme = call_773411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773411.url(scheme.get, call_773411.host, call_773411.base,
                         call_773411.route, valid.getOrDefault("path"))
  result = hook(call_773411, url, valid)

proc call*(call_773412: Call_DescribeCertificates_773397; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeCertificates
  ## Provides a description of the certificate.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773413 = newJObject()
  var body_773414 = newJObject()
  add(query_773413, "MaxRecords", newJString(MaxRecords))
  add(query_773413, "Marker", newJString(Marker))
  if body != nil:
    body_773414 = body
  result = call_773412.call(nil, query_773413, nil, nil, body_773414)

var describeCertificates* = Call_DescribeCertificates_773397(
    name: "describeCertificates", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeCertificates",
    validator: validate_DescribeCertificates_773398, base: "/",
    url: url_DescribeCertificates_773399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConnections_773416 = ref object of OpenApiRestCall_772597
proc url_DescribeConnections_773418(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeConnections_773417(path: JsonNode; query: JsonNode;
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
  var valid_773419 = query.getOrDefault("MaxRecords")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "MaxRecords", valid_773419
  var valid_773420 = query.getOrDefault("Marker")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "Marker", valid_773420
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
  var valid_773421 = header.getOrDefault("X-Amz-Date")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-Date", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Security-Token")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Security-Token", valid_773422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773423 = header.getOrDefault("X-Amz-Target")
  valid_773423 = validateParameter(valid_773423, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeConnections"))
  if valid_773423 != nil:
    section.add "X-Amz-Target", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Content-Sha256", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Algorithm")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Algorithm", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Signature")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Signature", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-SignedHeaders", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Credential")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Credential", valid_773428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773430: Call_DescribeConnections_773416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ## 
  let valid = call_773430.validator(path, query, header, formData, body)
  let scheme = call_773430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773430.url(scheme.get, call_773430.host, call_773430.base,
                         call_773430.route, valid.getOrDefault("path"))
  result = hook(call_773430, url, valid)

proc call*(call_773431: Call_DescribeConnections_773416; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeConnections
  ## Describes the status of the connections that have been made between the replication instance and an endpoint. Connections are created when you test an endpoint.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773432 = newJObject()
  var body_773433 = newJObject()
  add(query_773432, "MaxRecords", newJString(MaxRecords))
  add(query_773432, "Marker", newJString(Marker))
  if body != nil:
    body_773433 = body
  result = call_773431.call(nil, query_773432, nil, nil, body_773433)

var describeConnections* = Call_DescribeConnections_773416(
    name: "describeConnections", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeConnections",
    validator: validate_DescribeConnections_773417, base: "/",
    url: url_DescribeConnections_773418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointTypes_773434 = ref object of OpenApiRestCall_772597
proc url_DescribeEndpointTypes_773436(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpointTypes_773435(path: JsonNode; query: JsonNode;
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
  var valid_773437 = query.getOrDefault("MaxRecords")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "MaxRecords", valid_773437
  var valid_773438 = query.getOrDefault("Marker")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "Marker", valid_773438
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
  var valid_773439 = header.getOrDefault("X-Amz-Date")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Date", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Security-Token")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Security-Token", valid_773440
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773441 = header.getOrDefault("X-Amz-Target")
  valid_773441 = validateParameter(valid_773441, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEndpointTypes"))
  if valid_773441 != nil:
    section.add "X-Amz-Target", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Content-Sha256", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Algorithm")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Algorithm", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Signature")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Signature", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-SignedHeaders", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Credential")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Credential", valid_773446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773448: Call_DescribeEndpointTypes_773434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the type of endpoints available.
  ## 
  let valid = call_773448.validator(path, query, header, formData, body)
  let scheme = call_773448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773448.url(scheme.get, call_773448.host, call_773448.base,
                         call_773448.route, valid.getOrDefault("path"))
  result = hook(call_773448, url, valid)

proc call*(call_773449: Call_DescribeEndpointTypes_773434; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpointTypes
  ## Returns information about the type of endpoints available.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773450 = newJObject()
  var body_773451 = newJObject()
  add(query_773450, "MaxRecords", newJString(MaxRecords))
  add(query_773450, "Marker", newJString(Marker))
  if body != nil:
    body_773451 = body
  result = call_773449.call(nil, query_773450, nil, nil, body_773451)

var describeEndpointTypes* = Call_DescribeEndpointTypes_773434(
    name: "describeEndpointTypes", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpointTypes",
    validator: validate_DescribeEndpointTypes_773435, base: "/",
    url: url_DescribeEndpointTypes_773436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoints_773452 = ref object of OpenApiRestCall_772597
proc url_DescribeEndpoints_773454(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpoints_773453(path: JsonNode; query: JsonNode;
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
  var valid_773455 = query.getOrDefault("MaxRecords")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "MaxRecords", valid_773455
  var valid_773456 = query.getOrDefault("Marker")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "Marker", valid_773456
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
      "AmazonDMSv20160101.DescribeEndpoints"))
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

proc call*(call_773466: Call_DescribeEndpoints_773452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the endpoints for your account in the current region.
  ## 
  let valid = call_773466.validator(path, query, header, formData, body)
  let scheme = call_773466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773466.url(scheme.get, call_773466.host, call_773466.base,
                         call_773466.route, valid.getOrDefault("path"))
  result = hook(call_773466, url, valid)

proc call*(call_773467: Call_DescribeEndpoints_773452; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEndpoints
  ## Returns information about the endpoints for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773468 = newJObject()
  var body_773469 = newJObject()
  add(query_773468, "MaxRecords", newJString(MaxRecords))
  add(query_773468, "Marker", newJString(Marker))
  if body != nil:
    body_773469 = body
  result = call_773467.call(nil, query_773468, nil, nil, body_773469)

var describeEndpoints* = Call_DescribeEndpoints_773452(name: "describeEndpoints",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEndpoints",
    validator: validate_DescribeEndpoints_773453, base: "/",
    url: url_DescribeEndpoints_773454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventCategories_773470 = ref object of OpenApiRestCall_772597
proc url_DescribeEventCategories_773472(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEventCategories_773471(path: JsonNode; query: JsonNode;
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
  var valid_773473 = header.getOrDefault("X-Amz-Date")
  valid_773473 = validateParameter(valid_773473, JString, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "X-Amz-Date", valid_773473
  var valid_773474 = header.getOrDefault("X-Amz-Security-Token")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "X-Amz-Security-Token", valid_773474
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773475 = header.getOrDefault("X-Amz-Target")
  valid_773475 = validateParameter(valid_773475, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventCategories"))
  if valid_773475 != nil:
    section.add "X-Amz-Target", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Content-Sha256", valid_773476
  var valid_773477 = header.getOrDefault("X-Amz-Algorithm")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "X-Amz-Algorithm", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Signature")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Signature", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-SignedHeaders", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Credential")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Credential", valid_773480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773482: Call_DescribeEventCategories_773470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ## 
  let valid = call_773482.validator(path, query, header, formData, body)
  let scheme = call_773482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773482.url(scheme.get, call_773482.host, call_773482.base,
                         call_773482.route, valid.getOrDefault("path"))
  result = hook(call_773482, url, valid)

proc call*(call_773483: Call_DescribeEventCategories_773470; body: JsonNode): Recallable =
  ## describeEventCategories
  ## Lists categories for all event source types, or, if specified, for a specified source type. You can see a list of the event categories and source types in <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration Service User Guide.</i> 
  ##   body: JObject (required)
  var body_773484 = newJObject()
  if body != nil:
    body_773484 = body
  result = call_773483.call(nil, nil, nil, nil, body_773484)

var describeEventCategories* = Call_DescribeEventCategories_773470(
    name: "describeEventCategories", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventCategories",
    validator: validate_DescribeEventCategories_773471, base: "/",
    url: url_DescribeEventCategories_773472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventSubscriptions_773485 = ref object of OpenApiRestCall_772597
proc url_DescribeEventSubscriptions_773487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEventSubscriptions_773486(path: JsonNode; query: JsonNode;
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
  var valid_773488 = query.getOrDefault("MaxRecords")
  valid_773488 = validateParameter(valid_773488, JString, required = false,
                                 default = nil)
  if valid_773488 != nil:
    section.add "MaxRecords", valid_773488
  var valid_773489 = query.getOrDefault("Marker")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "Marker", valid_773489
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
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773492 = header.getOrDefault("X-Amz-Target")
  valid_773492 = validateParameter(valid_773492, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEventSubscriptions"))
  if valid_773492 != nil:
    section.add "X-Amz-Target", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Content-Sha256", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Algorithm")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Algorithm", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Signature")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Signature", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-SignedHeaders", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Credential")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Credential", valid_773497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773499: Call_DescribeEventSubscriptions_773485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ## 
  let valid = call_773499.validator(path, query, header, formData, body)
  let scheme = call_773499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773499.url(scheme.get, call_773499.host, call_773499.base,
                         call_773499.route, valid.getOrDefault("path"))
  result = hook(call_773499, url, valid)

proc call*(call_773500: Call_DescribeEventSubscriptions_773485; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEventSubscriptions
  ## <p>Lists all the event subscriptions for a customer account. The description of a subscription includes <code>SubscriptionName</code>, <code>SNSTopicARN</code>, <code>CustomerID</code>, <code>SourceType</code>, <code>SourceID</code>, <code>CreationTime</code>, and <code>Status</code>. </p> <p>If you specify <code>SubscriptionName</code>, this action lists the description for that subscription.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773501 = newJObject()
  var body_773502 = newJObject()
  add(query_773501, "MaxRecords", newJString(MaxRecords))
  add(query_773501, "Marker", newJString(Marker))
  if body != nil:
    body_773502 = body
  result = call_773500.call(nil, query_773501, nil, nil, body_773502)

var describeEventSubscriptions* = Call_DescribeEventSubscriptions_773485(
    name: "describeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEventSubscriptions",
    validator: validate_DescribeEventSubscriptions_773486, base: "/",
    url: url_DescribeEventSubscriptions_773487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvents_773503 = ref object of OpenApiRestCall_772597
proc url_DescribeEvents_773505(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEvents_773504(path: JsonNode; query: JsonNode;
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
  var valid_773506 = query.getOrDefault("MaxRecords")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "MaxRecords", valid_773506
  var valid_773507 = query.getOrDefault("Marker")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "Marker", valid_773507
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
  var valid_773508 = header.getOrDefault("X-Amz-Date")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Date", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Security-Token")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Security-Token", valid_773509
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773510 = header.getOrDefault("X-Amz-Target")
  valid_773510 = validateParameter(valid_773510, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeEvents"))
  if valid_773510 != nil:
    section.add "X-Amz-Target", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-Content-Sha256", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Algorithm")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Algorithm", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Signature")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Signature", valid_773513
  var valid_773514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-SignedHeaders", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Credential")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Credential", valid_773515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773517: Call_DescribeEvents_773503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ## 
  let valid = call_773517.validator(path, query, header, formData, body)
  let scheme = call_773517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773517.url(scheme.get, call_773517.host, call_773517.base,
                         call_773517.route, valid.getOrDefault("path"))
  result = hook(call_773517, url, valid)

proc call*(call_773518: Call_DescribeEvents_773503; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeEvents
  ##  Lists events for a given source identifier and source type. You can also specify a start and end time. For more information on AWS DMS events, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html">Working with Events and Notifications</a> in the <i>AWS Database Migration User Guide.</i> 
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773519 = newJObject()
  var body_773520 = newJObject()
  add(query_773519, "MaxRecords", newJString(MaxRecords))
  add(query_773519, "Marker", newJString(Marker))
  if body != nil:
    body_773520 = body
  result = call_773518.call(nil, query_773519, nil, nil, body_773520)

var describeEvents* = Call_DescribeEvents_773503(name: "describeEvents",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeEvents",
    validator: validate_DescribeEvents_773504, base: "/", url: url_DescribeEvents_773505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrderableReplicationInstances_773521 = ref object of OpenApiRestCall_772597
proc url_DescribeOrderableReplicationInstances_773523(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeOrderableReplicationInstances_773522(path: JsonNode;
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
  var valid_773524 = query.getOrDefault("MaxRecords")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "MaxRecords", valid_773524
  var valid_773525 = query.getOrDefault("Marker")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "Marker", valid_773525
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
  var valid_773526 = header.getOrDefault("X-Amz-Date")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-Date", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Security-Token")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Security-Token", valid_773527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773528 = header.getOrDefault("X-Amz-Target")
  valid_773528 = validateParameter(valid_773528, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeOrderableReplicationInstances"))
  if valid_773528 != nil:
    section.add "X-Amz-Target", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Content-Sha256", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Algorithm")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Algorithm", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Signature")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Signature", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-SignedHeaders", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Credential")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Credential", valid_773533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773535: Call_DescribeOrderableReplicationInstances_773521;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication instance types that can be created in the specified region.
  ## 
  let valid = call_773535.validator(path, query, header, formData, body)
  let scheme = call_773535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773535.url(scheme.get, call_773535.host, call_773535.base,
                         call_773535.route, valid.getOrDefault("path"))
  result = hook(call_773535, url, valid)

proc call*(call_773536: Call_DescribeOrderableReplicationInstances_773521;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeOrderableReplicationInstances
  ## Returns information about the replication instance types that can be created in the specified region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773537 = newJObject()
  var body_773538 = newJObject()
  add(query_773537, "MaxRecords", newJString(MaxRecords))
  add(query_773537, "Marker", newJString(Marker))
  if body != nil:
    body_773538 = body
  result = call_773536.call(nil, query_773537, nil, nil, body_773538)

var describeOrderableReplicationInstances* = Call_DescribeOrderableReplicationInstances_773521(
    name: "describeOrderableReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeOrderableReplicationInstances",
    validator: validate_DescribeOrderableReplicationInstances_773522, base: "/",
    url: url_DescribeOrderableReplicationInstances_773523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingMaintenanceActions_773539 = ref object of OpenApiRestCall_772597
proc url_DescribePendingMaintenanceActions_773541(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePendingMaintenanceActions_773540(path: JsonNode;
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
  var valid_773542 = query.getOrDefault("MaxRecords")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "MaxRecords", valid_773542
  var valid_773543 = query.getOrDefault("Marker")
  valid_773543 = validateParameter(valid_773543, JString, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "Marker", valid_773543
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
  var valid_773544 = header.getOrDefault("X-Amz-Date")
  valid_773544 = validateParameter(valid_773544, JString, required = false,
                                 default = nil)
  if valid_773544 != nil:
    section.add "X-Amz-Date", valid_773544
  var valid_773545 = header.getOrDefault("X-Amz-Security-Token")
  valid_773545 = validateParameter(valid_773545, JString, required = false,
                                 default = nil)
  if valid_773545 != nil:
    section.add "X-Amz-Security-Token", valid_773545
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773546 = header.getOrDefault("X-Amz-Target")
  valid_773546 = validateParameter(valid_773546, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribePendingMaintenanceActions"))
  if valid_773546 != nil:
    section.add "X-Amz-Target", valid_773546
  var valid_773547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Content-Sha256", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Algorithm")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Algorithm", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Signature")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Signature", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-SignedHeaders", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Credential")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Credential", valid_773551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773553: Call_DescribePendingMaintenanceActions_773539;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## For internal use only
  ## 
  let valid = call_773553.validator(path, query, header, formData, body)
  let scheme = call_773553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773553.url(scheme.get, call_773553.host, call_773553.base,
                         call_773553.route, valid.getOrDefault("path"))
  result = hook(call_773553, url, valid)

proc call*(call_773554: Call_DescribePendingMaintenanceActions_773539;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describePendingMaintenanceActions
  ## For internal use only
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773555 = newJObject()
  var body_773556 = newJObject()
  add(query_773555, "MaxRecords", newJString(MaxRecords))
  add(query_773555, "Marker", newJString(Marker))
  if body != nil:
    body_773556 = body
  result = call_773554.call(nil, query_773555, nil, nil, body_773556)

var describePendingMaintenanceActions* = Call_DescribePendingMaintenanceActions_773539(
    name: "describePendingMaintenanceActions", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribePendingMaintenanceActions",
    validator: validate_DescribePendingMaintenanceActions_773540, base: "/",
    url: url_DescribePendingMaintenanceActions_773541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRefreshSchemasStatus_773557 = ref object of OpenApiRestCall_772597
proc url_DescribeRefreshSchemasStatus_773559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRefreshSchemasStatus_773558(path: JsonNode; query: JsonNode;
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
  var valid_773560 = header.getOrDefault("X-Amz-Date")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Date", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Security-Token")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Security-Token", valid_773561
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773562 = header.getOrDefault("X-Amz-Target")
  valid_773562 = validateParameter(valid_773562, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeRefreshSchemasStatus"))
  if valid_773562 != nil:
    section.add "X-Amz-Target", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Content-Sha256", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Algorithm")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Algorithm", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Signature")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Signature", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-SignedHeaders", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Credential")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Credential", valid_773567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773569: Call_DescribeRefreshSchemasStatus_773557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the status of the RefreshSchemas operation.
  ## 
  let valid = call_773569.validator(path, query, header, formData, body)
  let scheme = call_773569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773569.url(scheme.get, call_773569.host, call_773569.base,
                         call_773569.route, valid.getOrDefault("path"))
  result = hook(call_773569, url, valid)

proc call*(call_773570: Call_DescribeRefreshSchemasStatus_773557; body: JsonNode): Recallable =
  ## describeRefreshSchemasStatus
  ## Returns the status of the RefreshSchemas operation.
  ##   body: JObject (required)
  var body_773571 = newJObject()
  if body != nil:
    body_773571 = body
  result = call_773570.call(nil, nil, nil, nil, body_773571)

var describeRefreshSchemasStatus* = Call_DescribeRefreshSchemasStatus_773557(
    name: "describeRefreshSchemasStatus", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeRefreshSchemasStatus",
    validator: validate_DescribeRefreshSchemasStatus_773558, base: "/",
    url: url_DescribeRefreshSchemasStatus_773559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstanceTaskLogs_773572 = ref object of OpenApiRestCall_772597
proc url_DescribeReplicationInstanceTaskLogs_773574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationInstanceTaskLogs_773573(path: JsonNode;
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
  var valid_773575 = query.getOrDefault("MaxRecords")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "MaxRecords", valid_773575
  var valid_773576 = query.getOrDefault("Marker")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "Marker", valid_773576
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
      "AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs"))
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

proc call*(call_773586: Call_DescribeReplicationInstanceTaskLogs_773572;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the task logs for the specified task.
  ## 
  let valid = call_773586.validator(path, query, header, formData, body)
  let scheme = call_773586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773586.url(scheme.get, call_773586.host, call_773586.base,
                         call_773586.route, valid.getOrDefault("path"))
  result = hook(call_773586, url, valid)

proc call*(call_773587: Call_DescribeReplicationInstanceTaskLogs_773572;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstanceTaskLogs
  ## Returns information about the task logs for the specified task.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773588 = newJObject()
  var body_773589 = newJObject()
  add(query_773588, "MaxRecords", newJString(MaxRecords))
  add(query_773588, "Marker", newJString(Marker))
  if body != nil:
    body_773589 = body
  result = call_773587.call(nil, query_773588, nil, nil, body_773589)

var describeReplicationInstanceTaskLogs* = Call_DescribeReplicationInstanceTaskLogs_773572(
    name: "describeReplicationInstanceTaskLogs", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstanceTaskLogs",
    validator: validate_DescribeReplicationInstanceTaskLogs_773573, base: "/",
    url: url_DescribeReplicationInstanceTaskLogs_773574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationInstances_773590 = ref object of OpenApiRestCall_772597
proc url_DescribeReplicationInstances_773592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationInstances_773591(path: JsonNode; query: JsonNode;
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
  var valid_773593 = query.getOrDefault("MaxRecords")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "MaxRecords", valid_773593
  var valid_773594 = query.getOrDefault("Marker")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "Marker", valid_773594
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
  var valid_773595 = header.getOrDefault("X-Amz-Date")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Date", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Security-Token")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Security-Token", valid_773596
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773597 = header.getOrDefault("X-Amz-Target")
  valid_773597 = validateParameter(valid_773597, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationInstances"))
  if valid_773597 != nil:
    section.add "X-Amz-Target", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Content-Sha256", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Algorithm")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Algorithm", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Signature")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Signature", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-SignedHeaders", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Credential")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Credential", valid_773602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773604: Call_DescribeReplicationInstances_773590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication instances for your account in the current region.
  ## 
  let valid = call_773604.validator(path, query, header, formData, body)
  let scheme = call_773604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773604.url(scheme.get, call_773604.host, call_773604.base,
                         call_773604.route, valid.getOrDefault("path"))
  result = hook(call_773604, url, valid)

proc call*(call_773605: Call_DescribeReplicationInstances_773590; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationInstances
  ## Returns information about replication instances for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773606 = newJObject()
  var body_773607 = newJObject()
  add(query_773606, "MaxRecords", newJString(MaxRecords))
  add(query_773606, "Marker", newJString(Marker))
  if body != nil:
    body_773607 = body
  result = call_773605.call(nil, query_773606, nil, nil, body_773607)

var describeReplicationInstances* = Call_DescribeReplicationInstances_773590(
    name: "describeReplicationInstances", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationInstances",
    validator: validate_DescribeReplicationInstances_773591, base: "/",
    url: url_DescribeReplicationInstances_773592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationSubnetGroups_773608 = ref object of OpenApiRestCall_772597
proc url_DescribeReplicationSubnetGroups_773610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationSubnetGroups_773609(path: JsonNode;
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
  var valid_773611 = query.getOrDefault("MaxRecords")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "MaxRecords", valid_773611
  var valid_773612 = query.getOrDefault("Marker")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "Marker", valid_773612
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
  var valid_773613 = header.getOrDefault("X-Amz-Date")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Date", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Security-Token")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Security-Token", valid_773614
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773615 = header.getOrDefault("X-Amz-Target")
  valid_773615 = validateParameter(valid_773615, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationSubnetGroups"))
  if valid_773615 != nil:
    section.add "X-Amz-Target", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Content-Sha256", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Algorithm")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Algorithm", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Signature")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Signature", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-SignedHeaders", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Credential")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Credential", valid_773620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773622: Call_DescribeReplicationSubnetGroups_773608;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about the replication subnet groups.
  ## 
  let valid = call_773622.validator(path, query, header, formData, body)
  let scheme = call_773622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773622.url(scheme.get, call_773622.host, call_773622.base,
                         call_773622.route, valid.getOrDefault("path"))
  result = hook(call_773622, url, valid)

proc call*(call_773623: Call_DescribeReplicationSubnetGroups_773608;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationSubnetGroups
  ## Returns information about the replication subnet groups.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773624 = newJObject()
  var body_773625 = newJObject()
  add(query_773624, "MaxRecords", newJString(MaxRecords))
  add(query_773624, "Marker", newJString(Marker))
  if body != nil:
    body_773625 = body
  result = call_773623.call(nil, query_773624, nil, nil, body_773625)

var describeReplicationSubnetGroups* = Call_DescribeReplicationSubnetGroups_773608(
    name: "describeReplicationSubnetGroups", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationSubnetGroups",
    validator: validate_DescribeReplicationSubnetGroups_773609, base: "/",
    url: url_DescribeReplicationSubnetGroups_773610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTaskAssessmentResults_773626 = ref object of OpenApiRestCall_772597
proc url_DescribeReplicationTaskAssessmentResults_773628(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationTaskAssessmentResults_773627(path: JsonNode;
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
  var valid_773629 = query.getOrDefault("MaxRecords")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "MaxRecords", valid_773629
  var valid_773630 = query.getOrDefault("Marker")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "Marker", valid_773630
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
  var valid_773631 = header.getOrDefault("X-Amz-Date")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Date", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Security-Token")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Security-Token", valid_773632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773633 = header.getOrDefault("X-Amz-Target")
  valid_773633 = validateParameter(valid_773633, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults"))
  if valid_773633 != nil:
    section.add "X-Amz-Target", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-Content-Sha256", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Algorithm")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Algorithm", valid_773635
  var valid_773636 = header.getOrDefault("X-Amz-Signature")
  valid_773636 = validateParameter(valid_773636, JString, required = false,
                                 default = nil)
  if valid_773636 != nil:
    section.add "X-Amz-Signature", valid_773636
  var valid_773637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-SignedHeaders", valid_773637
  var valid_773638 = header.getOrDefault("X-Amz-Credential")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Credential", valid_773638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773640: Call_DescribeReplicationTaskAssessmentResults_773626;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ## 
  let valid = call_773640.validator(path, query, header, formData, body)
  let scheme = call_773640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773640.url(scheme.get, call_773640.host, call_773640.base,
                         call_773640.route, valid.getOrDefault("path"))
  result = hook(call_773640, url, valid)

proc call*(call_773641: Call_DescribeReplicationTaskAssessmentResults_773626;
          body: JsonNode; MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTaskAssessmentResults
  ## Returns the task assessment results from Amazon S3. This action always returns the latest results.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773642 = newJObject()
  var body_773643 = newJObject()
  add(query_773642, "MaxRecords", newJString(MaxRecords))
  add(query_773642, "Marker", newJString(Marker))
  if body != nil:
    body_773643 = body
  result = call_773641.call(nil, query_773642, nil, nil, body_773643)

var describeReplicationTaskAssessmentResults* = Call_DescribeReplicationTaskAssessmentResults_773626(
    name: "describeReplicationTaskAssessmentResults", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com", route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTaskAssessmentResults",
    validator: validate_DescribeReplicationTaskAssessmentResults_773627,
    base: "/", url: url_DescribeReplicationTaskAssessmentResults_773628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReplicationTasks_773644 = ref object of OpenApiRestCall_772597
proc url_DescribeReplicationTasks_773646(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReplicationTasks_773645(path: JsonNode; query: JsonNode;
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
  var valid_773647 = query.getOrDefault("MaxRecords")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "MaxRecords", valid_773647
  var valid_773648 = query.getOrDefault("Marker")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "Marker", valid_773648
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
  var valid_773649 = header.getOrDefault("X-Amz-Date")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Date", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Security-Token")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Security-Token", valid_773650
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773651 = header.getOrDefault("X-Amz-Target")
  valid_773651 = validateParameter(valid_773651, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeReplicationTasks"))
  if valid_773651 != nil:
    section.add "X-Amz-Target", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Content-Sha256", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-Algorithm")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-Algorithm", valid_773653
  var valid_773654 = header.getOrDefault("X-Amz-Signature")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Signature", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-SignedHeaders", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Credential")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Credential", valid_773656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773658: Call_DescribeReplicationTasks_773644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about replication tasks for your account in the current region.
  ## 
  let valid = call_773658.validator(path, query, header, formData, body)
  let scheme = call_773658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773658.url(scheme.get, call_773658.host, call_773658.base,
                         call_773658.route, valid.getOrDefault("path"))
  result = hook(call_773658, url, valid)

proc call*(call_773659: Call_DescribeReplicationTasks_773644; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeReplicationTasks
  ## Returns information about replication tasks for your account in the current region.
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773660 = newJObject()
  var body_773661 = newJObject()
  add(query_773660, "MaxRecords", newJString(MaxRecords))
  add(query_773660, "Marker", newJString(Marker))
  if body != nil:
    body_773661 = body
  result = call_773659.call(nil, query_773660, nil, nil, body_773661)

var describeReplicationTasks* = Call_DescribeReplicationTasks_773644(
    name: "describeReplicationTasks", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeReplicationTasks",
    validator: validate_DescribeReplicationTasks_773645, base: "/",
    url: url_DescribeReplicationTasks_773646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchemas_773662 = ref object of OpenApiRestCall_772597
proc url_DescribeSchemas_773664(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSchemas_773663(path: JsonNode; query: JsonNode;
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
  var valid_773665 = query.getOrDefault("MaxRecords")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "MaxRecords", valid_773665
  var valid_773666 = query.getOrDefault("Marker")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "Marker", valid_773666
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
  var valid_773667 = header.getOrDefault("X-Amz-Date")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Date", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-Security-Token")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Security-Token", valid_773668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773669 = header.getOrDefault("X-Amz-Target")
  valid_773669 = validateParameter(valid_773669, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeSchemas"))
  if valid_773669 != nil:
    section.add "X-Amz-Target", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Content-Sha256", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Algorithm")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Algorithm", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Signature")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Signature", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-SignedHeaders", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Credential")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Credential", valid_773674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773676: Call_DescribeSchemas_773662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ## 
  let valid = call_773676.validator(path, query, header, formData, body)
  let scheme = call_773676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773676.url(scheme.get, call_773676.host, call_773676.base,
                         call_773676.route, valid.getOrDefault("path"))
  result = hook(call_773676, url, valid)

proc call*(call_773677: Call_DescribeSchemas_773662; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeSchemas
  ## <p>Returns information about the schema for the specified endpoint.</p> <p/>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773678 = newJObject()
  var body_773679 = newJObject()
  add(query_773678, "MaxRecords", newJString(MaxRecords))
  add(query_773678, "Marker", newJString(Marker))
  if body != nil:
    body_773679 = body
  result = call_773677.call(nil, query_773678, nil, nil, body_773679)

var describeSchemas* = Call_DescribeSchemas_773662(name: "describeSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeSchemas",
    validator: validate_DescribeSchemas_773663, base: "/", url: url_DescribeSchemas_773664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTableStatistics_773680 = ref object of OpenApiRestCall_772597
proc url_DescribeTableStatistics_773682(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTableStatistics_773681(path: JsonNode; query: JsonNode;
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
  var valid_773683 = query.getOrDefault("MaxRecords")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "MaxRecords", valid_773683
  var valid_773684 = query.getOrDefault("Marker")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "Marker", valid_773684
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
  var valid_773685 = header.getOrDefault("X-Amz-Date")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Date", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Security-Token")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Security-Token", valid_773686
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773687 = header.getOrDefault("X-Amz-Target")
  valid_773687 = validateParameter(valid_773687, JString, required = true, default = newJString(
      "AmazonDMSv20160101.DescribeTableStatistics"))
  if valid_773687 != nil:
    section.add "X-Amz-Target", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-Content-Sha256", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Algorithm")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Algorithm", valid_773689
  var valid_773690 = header.getOrDefault("X-Amz-Signature")
  valid_773690 = validateParameter(valid_773690, JString, required = false,
                                 default = nil)
  if valid_773690 != nil:
    section.add "X-Amz-Signature", valid_773690
  var valid_773691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773691 = validateParameter(valid_773691, JString, required = false,
                                 default = nil)
  if valid_773691 != nil:
    section.add "X-Amz-SignedHeaders", valid_773691
  var valid_773692 = header.getOrDefault("X-Amz-Credential")
  valid_773692 = validateParameter(valid_773692, JString, required = false,
                                 default = nil)
  if valid_773692 != nil:
    section.add "X-Amz-Credential", valid_773692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773694: Call_DescribeTableStatistics_773680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ## 
  let valid = call_773694.validator(path, query, header, formData, body)
  let scheme = call_773694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773694.url(scheme.get, call_773694.host, call_773694.base,
                         call_773694.route, valid.getOrDefault("path"))
  result = hook(call_773694, url, valid)

proc call*(call_773695: Call_DescribeTableStatistics_773680; body: JsonNode;
          MaxRecords: string = ""; Marker: string = ""): Recallable =
  ## describeTableStatistics
  ## <p>Returns table statistics on the database migration task, including table name, rows inserted, rows updated, and rows deleted.</p> <p>Note that the "last updated" column the DMS console only indicates the time that AWS DMS last updated the table statistics record for a table. It does not indicate the time of the last update to the table.</p>
  ##   MaxRecords: string
  ##             : Pagination limit
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_773696 = newJObject()
  var body_773697 = newJObject()
  add(query_773696, "MaxRecords", newJString(MaxRecords))
  add(query_773696, "Marker", newJString(Marker))
  if body != nil:
    body_773697 = body
  result = call_773695.call(nil, query_773696, nil, nil, body_773697)

var describeTableStatistics* = Call_DescribeTableStatistics_773680(
    name: "describeTableStatistics", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.DescribeTableStatistics",
    validator: validate_DescribeTableStatistics_773681, base: "/",
    url: url_DescribeTableStatistics_773682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCertificate_773698 = ref object of OpenApiRestCall_772597
proc url_ImportCertificate_773700(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ImportCertificate_773699(path: JsonNode; query: JsonNode;
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
  var valid_773701 = header.getOrDefault("X-Amz-Date")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Date", valid_773701
  var valid_773702 = header.getOrDefault("X-Amz-Security-Token")
  valid_773702 = validateParameter(valid_773702, JString, required = false,
                                 default = nil)
  if valid_773702 != nil:
    section.add "X-Amz-Security-Token", valid_773702
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773703 = header.getOrDefault("X-Amz-Target")
  valid_773703 = validateParameter(valid_773703, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ImportCertificate"))
  if valid_773703 != nil:
    section.add "X-Amz-Target", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Content-Sha256", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Algorithm")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Algorithm", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-Signature")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-Signature", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-SignedHeaders", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Credential")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Credential", valid_773708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773710: Call_ImportCertificate_773698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Uploads the specified certificate.
  ## 
  let valid = call_773710.validator(path, query, header, formData, body)
  let scheme = call_773710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773710.url(scheme.get, call_773710.host, call_773710.base,
                         call_773710.route, valid.getOrDefault("path"))
  result = hook(call_773710, url, valid)

proc call*(call_773711: Call_ImportCertificate_773698; body: JsonNode): Recallable =
  ## importCertificate
  ## Uploads the specified certificate.
  ##   body: JObject (required)
  var body_773712 = newJObject()
  if body != nil:
    body_773712 = body
  result = call_773711.call(nil, nil, nil, nil, body_773712)

var importCertificate* = Call_ImportCertificate_773698(name: "importCertificate",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ImportCertificate",
    validator: validate_ImportCertificate_773699, base: "/",
    url: url_ImportCertificate_773700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773713 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773715(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_773714(path: JsonNode; query: JsonNode;
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
  var valid_773716 = header.getOrDefault("X-Amz-Date")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Date", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Security-Token")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Security-Token", valid_773717
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773718 = header.getOrDefault("X-Amz-Target")
  valid_773718 = validateParameter(valid_773718, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ListTagsForResource"))
  if valid_773718 != nil:
    section.add "X-Amz-Target", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Content-Sha256", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Algorithm")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Algorithm", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-Signature")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-Signature", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-SignedHeaders", valid_773722
  var valid_773723 = header.getOrDefault("X-Amz-Credential")
  valid_773723 = validateParameter(valid_773723, JString, required = false,
                                 default = nil)
  if valid_773723 != nil:
    section.add "X-Amz-Credential", valid_773723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773725: Call_ListTagsForResource_773713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags for an AWS DMS resource.
  ## 
  let valid = call_773725.validator(path, query, header, formData, body)
  let scheme = call_773725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773725.url(scheme.get, call_773725.host, call_773725.base,
                         call_773725.route, valid.getOrDefault("path"))
  result = hook(call_773725, url, valid)

proc call*(call_773726: Call_ListTagsForResource_773713; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags for an AWS DMS resource.
  ##   body: JObject (required)
  var body_773727 = newJObject()
  if body != nil:
    body_773727 = body
  result = call_773726.call(nil, nil, nil, nil, body_773727)

var listTagsForResource* = Call_ListTagsForResource_773713(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ListTagsForResource",
    validator: validate_ListTagsForResource_773714, base: "/",
    url: url_ListTagsForResource_773715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEndpoint_773728 = ref object of OpenApiRestCall_772597
proc url_ModifyEndpoint_773730(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyEndpoint_773729(path: JsonNode; query: JsonNode;
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
  var valid_773731 = header.getOrDefault("X-Amz-Date")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Date", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Security-Token")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Security-Token", valid_773732
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773733 = header.getOrDefault("X-Amz-Target")
  valid_773733 = validateParameter(valid_773733, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEndpoint"))
  if valid_773733 != nil:
    section.add "X-Amz-Target", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Content-Sha256", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-Algorithm")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Algorithm", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-Signature")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Signature", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-SignedHeaders", valid_773737
  var valid_773738 = header.getOrDefault("X-Amz-Credential")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Credential", valid_773738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773740: Call_ModifyEndpoint_773728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the specified endpoint.
  ## 
  let valid = call_773740.validator(path, query, header, formData, body)
  let scheme = call_773740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773740.url(scheme.get, call_773740.host, call_773740.base,
                         call_773740.route, valid.getOrDefault("path"))
  result = hook(call_773740, url, valid)

proc call*(call_773741: Call_ModifyEndpoint_773728; body: JsonNode): Recallable =
  ## modifyEndpoint
  ## Modifies the specified endpoint.
  ##   body: JObject (required)
  var body_773742 = newJObject()
  if body != nil:
    body_773742 = body
  result = call_773741.call(nil, nil, nil, nil, body_773742)

var modifyEndpoint* = Call_ModifyEndpoint_773728(name: "modifyEndpoint",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEndpoint",
    validator: validate_ModifyEndpoint_773729, base: "/", url: url_ModifyEndpoint_773730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyEventSubscription_773743 = ref object of OpenApiRestCall_772597
proc url_ModifyEventSubscription_773745(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyEventSubscription_773744(path: JsonNode; query: JsonNode;
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
  var valid_773746 = header.getOrDefault("X-Amz-Date")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Date", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Security-Token")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Security-Token", valid_773747
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773748 = header.getOrDefault("X-Amz-Target")
  valid_773748 = validateParameter(valid_773748, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyEventSubscription"))
  if valid_773748 != nil:
    section.add "X-Amz-Target", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Content-Sha256", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Algorithm")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Algorithm", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Signature")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Signature", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-SignedHeaders", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Credential")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Credential", valid_773753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773755: Call_ModifyEventSubscription_773743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing AWS DMS event notification subscription. 
  ## 
  let valid = call_773755.validator(path, query, header, formData, body)
  let scheme = call_773755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773755.url(scheme.get, call_773755.host, call_773755.base,
                         call_773755.route, valid.getOrDefault("path"))
  result = hook(call_773755, url, valid)

proc call*(call_773756: Call_ModifyEventSubscription_773743; body: JsonNode): Recallable =
  ## modifyEventSubscription
  ## Modifies an existing AWS DMS event notification subscription. 
  ##   body: JObject (required)
  var body_773757 = newJObject()
  if body != nil:
    body_773757 = body
  result = call_773756.call(nil, nil, nil, nil, body_773757)

var modifyEventSubscription* = Call_ModifyEventSubscription_773743(
    name: "modifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyEventSubscription",
    validator: validate_ModifyEventSubscription_773744, base: "/",
    url: url_ModifyEventSubscription_773745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationInstance_773758 = ref object of OpenApiRestCall_772597
proc url_ModifyReplicationInstance_773760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReplicationInstance_773759(path: JsonNode; query: JsonNode;
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
  var valid_773761 = header.getOrDefault("X-Amz-Date")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "X-Amz-Date", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-Security-Token")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Security-Token", valid_773762
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773763 = header.getOrDefault("X-Amz-Target")
  valid_773763 = validateParameter(valid_773763, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationInstance"))
  if valid_773763 != nil:
    section.add "X-Amz-Target", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Content-Sha256", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Algorithm")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Algorithm", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Signature")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Signature", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-SignedHeaders", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Credential")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Credential", valid_773768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773770: Call_ModifyReplicationInstance_773758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ## 
  let valid = call_773770.validator(path, query, header, formData, body)
  let scheme = call_773770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773770.url(scheme.get, call_773770.host, call_773770.base,
                         call_773770.route, valid.getOrDefault("path"))
  result = hook(call_773770, url, valid)

proc call*(call_773771: Call_ModifyReplicationInstance_773758; body: JsonNode): Recallable =
  ## modifyReplicationInstance
  ## <p>Modifies the replication instance to apply new settings. You can change one or more parameters by specifying these parameters and the new values in the request.</p> <p>Some settings are applied during the maintenance window.</p> <p/>
  ##   body: JObject (required)
  var body_773772 = newJObject()
  if body != nil:
    body_773772 = body
  result = call_773771.call(nil, nil, nil, nil, body_773772)

var modifyReplicationInstance* = Call_ModifyReplicationInstance_773758(
    name: "modifyReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationInstance",
    validator: validate_ModifyReplicationInstance_773759, base: "/",
    url: url_ModifyReplicationInstance_773760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationSubnetGroup_773773 = ref object of OpenApiRestCall_772597
proc url_ModifyReplicationSubnetGroup_773775(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReplicationSubnetGroup_773774(path: JsonNode; query: JsonNode;
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
  var valid_773776 = header.getOrDefault("X-Amz-Date")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Date", valid_773776
  var valid_773777 = header.getOrDefault("X-Amz-Security-Token")
  valid_773777 = validateParameter(valid_773777, JString, required = false,
                                 default = nil)
  if valid_773777 != nil:
    section.add "X-Amz-Security-Token", valid_773777
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773778 = header.getOrDefault("X-Amz-Target")
  valid_773778 = validateParameter(valid_773778, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationSubnetGroup"))
  if valid_773778 != nil:
    section.add "X-Amz-Target", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Content-Sha256", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Algorithm")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Algorithm", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-Signature")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-Signature", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-SignedHeaders", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Credential")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Credential", valid_773783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773785: Call_ModifyReplicationSubnetGroup_773773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings for the specified replication subnet group.
  ## 
  let valid = call_773785.validator(path, query, header, formData, body)
  let scheme = call_773785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773785.url(scheme.get, call_773785.host, call_773785.base,
                         call_773785.route, valid.getOrDefault("path"))
  result = hook(call_773785, url, valid)

proc call*(call_773786: Call_ModifyReplicationSubnetGroup_773773; body: JsonNode): Recallable =
  ## modifyReplicationSubnetGroup
  ## Modifies the settings for the specified replication subnet group.
  ##   body: JObject (required)
  var body_773787 = newJObject()
  if body != nil:
    body_773787 = body
  result = call_773786.call(nil, nil, nil, nil, body_773787)

var modifyReplicationSubnetGroup* = Call_ModifyReplicationSubnetGroup_773773(
    name: "modifyReplicationSubnetGroup", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationSubnetGroup",
    validator: validate_ModifyReplicationSubnetGroup_773774, base: "/",
    url: url_ModifyReplicationSubnetGroup_773775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyReplicationTask_773788 = ref object of OpenApiRestCall_772597
proc url_ModifyReplicationTask_773790(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyReplicationTask_773789(path: JsonNode; query: JsonNode;
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
  var valid_773791 = header.getOrDefault("X-Amz-Date")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Date", valid_773791
  var valid_773792 = header.getOrDefault("X-Amz-Security-Token")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "X-Amz-Security-Token", valid_773792
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773793 = header.getOrDefault("X-Amz-Target")
  valid_773793 = validateParameter(valid_773793, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ModifyReplicationTask"))
  if valid_773793 != nil:
    section.add "X-Amz-Target", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Content-Sha256", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-Algorithm")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Algorithm", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-Signature")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-Signature", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-SignedHeaders", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Credential")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Credential", valid_773798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773800: Call_ModifyReplicationTask_773788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ## 
  let valid = call_773800.validator(path, query, header, formData, body)
  let scheme = call_773800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773800.url(scheme.get, call_773800.host, call_773800.base,
                         call_773800.route, valid.getOrDefault("path"))
  result = hook(call_773800, url, valid)

proc call*(call_773801: Call_ModifyReplicationTask_773788; body: JsonNode): Recallable =
  ## modifyReplicationTask
  ## <p>Modifies the specified replication task.</p> <p>You can't modify the task endpoints. The task must be stopped before you can modify it. </p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks</a> in the <i>AWS Database Migration Service User Guide</i>.</p>
  ##   body: JObject (required)
  var body_773802 = newJObject()
  if body != nil:
    body_773802 = body
  result = call_773801.call(nil, nil, nil, nil, body_773802)

var modifyReplicationTask* = Call_ModifyReplicationTask_773788(
    name: "modifyReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ModifyReplicationTask",
    validator: validate_ModifyReplicationTask_773789, base: "/",
    url: url_ModifyReplicationTask_773790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RebootReplicationInstance_773803 = ref object of OpenApiRestCall_772597
proc url_RebootReplicationInstance_773805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RebootReplicationInstance_773804(path: JsonNode; query: JsonNode;
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
  var valid_773806 = header.getOrDefault("X-Amz-Date")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Date", valid_773806
  var valid_773807 = header.getOrDefault("X-Amz-Security-Token")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "X-Amz-Security-Token", valid_773807
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773808 = header.getOrDefault("X-Amz-Target")
  valid_773808 = validateParameter(valid_773808, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RebootReplicationInstance"))
  if valid_773808 != nil:
    section.add "X-Amz-Target", valid_773808
  var valid_773809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-Content-Sha256", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-Algorithm")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-Algorithm", valid_773810
  var valid_773811 = header.getOrDefault("X-Amz-Signature")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-Signature", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-SignedHeaders", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Credential")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Credential", valid_773813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773815: Call_RebootReplicationInstance_773803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ## 
  let valid = call_773815.validator(path, query, header, formData, body)
  let scheme = call_773815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773815.url(scheme.get, call_773815.host, call_773815.base,
                         call_773815.route, valid.getOrDefault("path"))
  result = hook(call_773815, url, valid)

proc call*(call_773816: Call_RebootReplicationInstance_773803; body: JsonNode): Recallable =
  ## rebootReplicationInstance
  ## Reboots a replication instance. Rebooting results in a momentary outage, until the replication instance becomes available again.
  ##   body: JObject (required)
  var body_773817 = newJObject()
  if body != nil:
    body_773817 = body
  result = call_773816.call(nil, nil, nil, nil, body_773817)

var rebootReplicationInstance* = Call_RebootReplicationInstance_773803(
    name: "rebootReplicationInstance", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RebootReplicationInstance",
    validator: validate_RebootReplicationInstance_773804, base: "/",
    url: url_RebootReplicationInstance_773805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RefreshSchemas_773818 = ref object of OpenApiRestCall_772597
proc url_RefreshSchemas_773820(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RefreshSchemas_773819(path: JsonNode; query: JsonNode;
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
  var valid_773821 = header.getOrDefault("X-Amz-Date")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Date", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-Security-Token")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-Security-Token", valid_773822
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773823 = header.getOrDefault("X-Amz-Target")
  valid_773823 = validateParameter(valid_773823, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RefreshSchemas"))
  if valid_773823 != nil:
    section.add "X-Amz-Target", valid_773823
  var valid_773824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Content-Sha256", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-Algorithm")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-Algorithm", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-Signature")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-Signature", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-SignedHeaders", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Credential")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Credential", valid_773828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773830: Call_RefreshSchemas_773818; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ## 
  let valid = call_773830.validator(path, query, header, formData, body)
  let scheme = call_773830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773830.url(scheme.get, call_773830.host, call_773830.base,
                         call_773830.route, valid.getOrDefault("path"))
  result = hook(call_773830, url, valid)

proc call*(call_773831: Call_RefreshSchemas_773818; body: JsonNode): Recallable =
  ## refreshSchemas
  ## Populates the schema for the specified endpoint. This is an asynchronous operation and can take several minutes. You can check the status of this operation by calling the DescribeRefreshSchemasStatus operation.
  ##   body: JObject (required)
  var body_773832 = newJObject()
  if body != nil:
    body_773832 = body
  result = call_773831.call(nil, nil, nil, nil, body_773832)

var refreshSchemas* = Call_RefreshSchemas_773818(name: "refreshSchemas",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RefreshSchemas",
    validator: validate_RefreshSchemas_773819, base: "/", url: url_RefreshSchemas_773820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReloadTables_773833 = ref object of OpenApiRestCall_772597
proc url_ReloadTables_773835(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ReloadTables_773834(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773836 = header.getOrDefault("X-Amz-Date")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Date", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-Security-Token")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Security-Token", valid_773837
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773838 = header.getOrDefault("X-Amz-Target")
  valid_773838 = validateParameter(valid_773838, JString, required = true, default = newJString(
      "AmazonDMSv20160101.ReloadTables"))
  if valid_773838 != nil:
    section.add "X-Amz-Target", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Content-Sha256", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Algorithm")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Algorithm", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-Signature")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-Signature", valid_773841
  var valid_773842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-SignedHeaders", valid_773842
  var valid_773843 = header.getOrDefault("X-Amz-Credential")
  valid_773843 = validateParameter(valid_773843, JString, required = false,
                                 default = nil)
  if valid_773843 != nil:
    section.add "X-Amz-Credential", valid_773843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773845: Call_ReloadTables_773833; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Reloads the target database table with the source data. 
  ## 
  let valid = call_773845.validator(path, query, header, formData, body)
  let scheme = call_773845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773845.url(scheme.get, call_773845.host, call_773845.base,
                         call_773845.route, valid.getOrDefault("path"))
  result = hook(call_773845, url, valid)

proc call*(call_773846: Call_ReloadTables_773833; body: JsonNode): Recallable =
  ## reloadTables
  ## Reloads the target database table with the source data. 
  ##   body: JObject (required)
  var body_773847 = newJObject()
  if body != nil:
    body_773847 = body
  result = call_773846.call(nil, nil, nil, nil, body_773847)

var reloadTables* = Call_ReloadTables_773833(name: "reloadTables",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.ReloadTables",
    validator: validate_ReloadTables_773834, base: "/", url: url_ReloadTables_773835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_773848 = ref object of OpenApiRestCall_772597
proc url_RemoveTagsFromResource_773850(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTagsFromResource_773849(path: JsonNode; query: JsonNode;
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
  var valid_773851 = header.getOrDefault("X-Amz-Date")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Date", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-Security-Token")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Security-Token", valid_773852
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773853 = header.getOrDefault("X-Amz-Target")
  valid_773853 = validateParameter(valid_773853, JString, required = true, default = newJString(
      "AmazonDMSv20160101.RemoveTagsFromResource"))
  if valid_773853 != nil:
    section.add "X-Amz-Target", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Content-Sha256", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Algorithm")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Algorithm", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Signature")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Signature", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-SignedHeaders", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Credential")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Credential", valid_773858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773860: Call_RemoveTagsFromResource_773848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes metadata tags from a DMS resource.
  ## 
  let valid = call_773860.validator(path, query, header, formData, body)
  let scheme = call_773860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773860.url(scheme.get, call_773860.host, call_773860.base,
                         call_773860.route, valid.getOrDefault("path"))
  result = hook(call_773860, url, valid)

proc call*(call_773861: Call_RemoveTagsFromResource_773848; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes metadata tags from a DMS resource.
  ##   body: JObject (required)
  var body_773862 = newJObject()
  if body != nil:
    body_773862 = body
  result = call_773861.call(nil, nil, nil, nil, body_773862)

var removeTagsFromResource* = Call_RemoveTagsFromResource_773848(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_773849, base: "/",
    url: url_RemoveTagsFromResource_773850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTask_773863 = ref object of OpenApiRestCall_772597
proc url_StartReplicationTask_773865(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartReplicationTask_773864(path: JsonNode; query: JsonNode;
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
  var valid_773866 = header.getOrDefault("X-Amz-Date")
  valid_773866 = validateParameter(valid_773866, JString, required = false,
                                 default = nil)
  if valid_773866 != nil:
    section.add "X-Amz-Date", valid_773866
  var valid_773867 = header.getOrDefault("X-Amz-Security-Token")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-Security-Token", valid_773867
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773868 = header.getOrDefault("X-Amz-Target")
  valid_773868 = validateParameter(valid_773868, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTask"))
  if valid_773868 != nil:
    section.add "X-Amz-Target", valid_773868
  var valid_773869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Content-Sha256", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Algorithm")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Algorithm", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-Signature")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-Signature", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-SignedHeaders", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Credential")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Credential", valid_773873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773875: Call_StartReplicationTask_773863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ## 
  let valid = call_773875.validator(path, query, header, formData, body)
  let scheme = call_773875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773875.url(scheme.get, call_773875.host, call_773875.base,
                         call_773875.route, valid.getOrDefault("path"))
  result = hook(call_773875, url, valid)

proc call*(call_773876: Call_StartReplicationTask_773863; body: JsonNode): Recallable =
  ## startReplicationTask
  ## <p>Starts the replication task.</p> <p>For more information about AWS DMS tasks, see <a href="https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.html">Working with Migration Tasks </a> in the <i>AWS Database Migration Service User Guide.</i> </p>
  ##   body: JObject (required)
  var body_773877 = newJObject()
  if body != nil:
    body_773877 = body
  result = call_773876.call(nil, nil, nil, nil, body_773877)

var startReplicationTask* = Call_StartReplicationTask_773863(
    name: "startReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTask",
    validator: validate_StartReplicationTask_773864, base: "/",
    url: url_StartReplicationTask_773865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartReplicationTaskAssessment_773878 = ref object of OpenApiRestCall_772597
proc url_StartReplicationTaskAssessment_773880(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartReplicationTaskAssessment_773879(path: JsonNode;
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
  var valid_773881 = header.getOrDefault("X-Amz-Date")
  valid_773881 = validateParameter(valid_773881, JString, required = false,
                                 default = nil)
  if valid_773881 != nil:
    section.add "X-Amz-Date", valid_773881
  var valid_773882 = header.getOrDefault("X-Amz-Security-Token")
  valid_773882 = validateParameter(valid_773882, JString, required = false,
                                 default = nil)
  if valid_773882 != nil:
    section.add "X-Amz-Security-Token", valid_773882
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773883 = header.getOrDefault("X-Amz-Target")
  valid_773883 = validateParameter(valid_773883, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StartReplicationTaskAssessment"))
  if valid_773883 != nil:
    section.add "X-Amz-Target", valid_773883
  var valid_773884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773884 = validateParameter(valid_773884, JString, required = false,
                                 default = nil)
  if valid_773884 != nil:
    section.add "X-Amz-Content-Sha256", valid_773884
  var valid_773885 = header.getOrDefault("X-Amz-Algorithm")
  valid_773885 = validateParameter(valid_773885, JString, required = false,
                                 default = nil)
  if valid_773885 != nil:
    section.add "X-Amz-Algorithm", valid_773885
  var valid_773886 = header.getOrDefault("X-Amz-Signature")
  valid_773886 = validateParameter(valid_773886, JString, required = false,
                                 default = nil)
  if valid_773886 != nil:
    section.add "X-Amz-Signature", valid_773886
  var valid_773887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-SignedHeaders", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Credential")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Credential", valid_773888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773890: Call_StartReplicationTaskAssessment_773878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ## 
  let valid = call_773890.validator(path, query, header, formData, body)
  let scheme = call_773890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773890.url(scheme.get, call_773890.host, call_773890.base,
                         call_773890.route, valid.getOrDefault("path"))
  result = hook(call_773890, url, valid)

proc call*(call_773891: Call_StartReplicationTaskAssessment_773878; body: JsonNode): Recallable =
  ## startReplicationTaskAssessment
  ##  Starts the replication task assessment for unsupported data types in the source database. 
  ##   body: JObject (required)
  var body_773892 = newJObject()
  if body != nil:
    body_773892 = body
  result = call_773891.call(nil, nil, nil, nil, body_773892)

var startReplicationTaskAssessment* = Call_StartReplicationTaskAssessment_773878(
    name: "startReplicationTaskAssessment", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StartReplicationTaskAssessment",
    validator: validate_StartReplicationTaskAssessment_773879, base: "/",
    url: url_StartReplicationTaskAssessment_773880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopReplicationTask_773893 = ref object of OpenApiRestCall_772597
proc url_StopReplicationTask_773895(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopReplicationTask_773894(path: JsonNode; query: JsonNode;
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
  var valid_773896 = header.getOrDefault("X-Amz-Date")
  valid_773896 = validateParameter(valid_773896, JString, required = false,
                                 default = nil)
  if valid_773896 != nil:
    section.add "X-Amz-Date", valid_773896
  var valid_773897 = header.getOrDefault("X-Amz-Security-Token")
  valid_773897 = validateParameter(valid_773897, JString, required = false,
                                 default = nil)
  if valid_773897 != nil:
    section.add "X-Amz-Security-Token", valid_773897
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773898 = header.getOrDefault("X-Amz-Target")
  valid_773898 = validateParameter(valid_773898, JString, required = true, default = newJString(
      "AmazonDMSv20160101.StopReplicationTask"))
  if valid_773898 != nil:
    section.add "X-Amz-Target", valid_773898
  var valid_773899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773899 = validateParameter(valid_773899, JString, required = false,
                                 default = nil)
  if valid_773899 != nil:
    section.add "X-Amz-Content-Sha256", valid_773899
  var valid_773900 = header.getOrDefault("X-Amz-Algorithm")
  valid_773900 = validateParameter(valid_773900, JString, required = false,
                                 default = nil)
  if valid_773900 != nil:
    section.add "X-Amz-Algorithm", valid_773900
  var valid_773901 = header.getOrDefault("X-Amz-Signature")
  valid_773901 = validateParameter(valid_773901, JString, required = false,
                                 default = nil)
  if valid_773901 != nil:
    section.add "X-Amz-Signature", valid_773901
  var valid_773902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-SignedHeaders", valid_773902
  var valid_773903 = header.getOrDefault("X-Amz-Credential")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Credential", valid_773903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773905: Call_StopReplicationTask_773893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops the replication task.</p> <p/>
  ## 
  let valid = call_773905.validator(path, query, header, formData, body)
  let scheme = call_773905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773905.url(scheme.get, call_773905.host, call_773905.base,
                         call_773905.route, valid.getOrDefault("path"))
  result = hook(call_773905, url, valid)

proc call*(call_773906: Call_StopReplicationTask_773893; body: JsonNode): Recallable =
  ## stopReplicationTask
  ## <p>Stops the replication task.</p> <p/>
  ##   body: JObject (required)
  var body_773907 = newJObject()
  if body != nil:
    body_773907 = body
  result = call_773906.call(nil, nil, nil, nil, body_773907)

var stopReplicationTask* = Call_StopReplicationTask_773893(
    name: "stopReplicationTask", meth: HttpMethod.HttpPost,
    host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.StopReplicationTask",
    validator: validate_StopReplicationTask_773894, base: "/",
    url: url_StopReplicationTask_773895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestConnection_773908 = ref object of OpenApiRestCall_772597
proc url_TestConnection_773910(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TestConnection_773909(path: JsonNode; query: JsonNode;
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
  var valid_773911 = header.getOrDefault("X-Amz-Date")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Date", valid_773911
  var valid_773912 = header.getOrDefault("X-Amz-Security-Token")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-Security-Token", valid_773912
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773913 = header.getOrDefault("X-Amz-Target")
  valid_773913 = validateParameter(valid_773913, JString, required = true, default = newJString(
      "AmazonDMSv20160101.TestConnection"))
  if valid_773913 != nil:
    section.add "X-Amz-Target", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Content-Sha256", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-Algorithm")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-Algorithm", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-Signature")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-Signature", valid_773916
  var valid_773917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773917 = validateParameter(valid_773917, JString, required = false,
                                 default = nil)
  if valid_773917 != nil:
    section.add "X-Amz-SignedHeaders", valid_773917
  var valid_773918 = header.getOrDefault("X-Amz-Credential")
  valid_773918 = validateParameter(valid_773918, JString, required = false,
                                 default = nil)
  if valid_773918 != nil:
    section.add "X-Amz-Credential", valid_773918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773920: Call_TestConnection_773908; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the connection between the replication instance and the endpoint.
  ## 
  let valid = call_773920.validator(path, query, header, formData, body)
  let scheme = call_773920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773920.url(scheme.get, call_773920.host, call_773920.base,
                         call_773920.route, valid.getOrDefault("path"))
  result = hook(call_773920, url, valid)

proc call*(call_773921: Call_TestConnection_773908; body: JsonNode): Recallable =
  ## testConnection
  ## Tests the connection between the replication instance and the endpoint.
  ##   body: JObject (required)
  var body_773922 = newJObject()
  if body != nil:
    body_773922 = body
  result = call_773921.call(nil, nil, nil, nil, body_773922)

var testConnection* = Call_TestConnection_773908(name: "testConnection",
    meth: HttpMethod.HttpPost, host: "dms.amazonaws.com",
    route: "/#X-Amz-Target=AmazonDMSv20160101.TestConnection",
    validator: validate_TestConnection_773909, base: "/", url: url_TestConnection_773910,
    schemes: {Scheme.Https, Scheme.Http})
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
