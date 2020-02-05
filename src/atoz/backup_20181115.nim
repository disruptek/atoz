
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Backup
## version: 2018-11-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Backup</fullname> <p>AWS Backup is a unified backup service designed to protect AWS services and their associated data. AWS Backup simplifies the creation, migration, restoration, and deletion of backups, while also providing reporting and auditing.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/backup/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "backup.ap-northeast-1.amazonaws.com", "ap-southeast-1": "backup.ap-southeast-1.amazonaws.com",
                           "us-west-2": "backup.us-west-2.amazonaws.com",
                           "eu-west-2": "backup.eu-west-2.amazonaws.com", "ap-northeast-3": "backup.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "backup.eu-central-1.amazonaws.com",
                           "us-east-2": "backup.us-east-2.amazonaws.com",
                           "us-east-1": "backup.us-east-1.amazonaws.com", "cn-northwest-1": "backup.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "backup.ap-south-1.amazonaws.com",
                           "eu-north-1": "backup.eu-north-1.amazonaws.com", "ap-northeast-2": "backup.ap-northeast-2.amazonaws.com",
                           "us-west-1": "backup.us-west-1.amazonaws.com", "us-gov-east-1": "backup.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "backup.eu-west-3.amazonaws.com",
                           "cn-north-1": "backup.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "backup.sa-east-1.amazonaws.com",
                           "eu-west-1": "backup.eu-west-1.amazonaws.com", "us-gov-west-1": "backup.us-gov-west-1.amazonaws.com", "ap-southeast-2": "backup.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "backup.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "backup.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "backup.ap-southeast-1.amazonaws.com",
      "us-west-2": "backup.us-west-2.amazonaws.com",
      "eu-west-2": "backup.eu-west-2.amazonaws.com",
      "ap-northeast-3": "backup.ap-northeast-3.amazonaws.com",
      "eu-central-1": "backup.eu-central-1.amazonaws.com",
      "us-east-2": "backup.us-east-2.amazonaws.com",
      "us-east-1": "backup.us-east-1.amazonaws.com",
      "cn-northwest-1": "backup.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "backup.ap-south-1.amazonaws.com",
      "eu-north-1": "backup.eu-north-1.amazonaws.com",
      "ap-northeast-2": "backup.ap-northeast-2.amazonaws.com",
      "us-west-1": "backup.us-west-1.amazonaws.com",
      "us-gov-east-1": "backup.us-gov-east-1.amazonaws.com",
      "eu-west-3": "backup.eu-west-3.amazonaws.com",
      "cn-north-1": "backup.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "backup.sa-east-1.amazonaws.com",
      "eu-west-1": "backup.eu-west-1.amazonaws.com",
      "us-gov-west-1": "backup.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "backup.ap-southeast-2.amazonaws.com",
      "ca-central-1": "backup.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "backup"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBackupPlan_613256 = ref object of OpenApiRestCall_612658
proc url_CreateBackupPlan_613258(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupPlan_613257(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613259 = header.getOrDefault("X-Amz-Signature")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Signature", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Content-Sha256", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Date")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Date", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Credential")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Credential", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Security-Token")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Security-Token", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Algorithm")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Algorithm", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-SignedHeaders", valid_613265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613267: Call_CreateBackupPlan_613256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ## 
  let valid = call_613267.validator(path, query, header, formData, body)
  let scheme = call_613267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613267.url(scheme.get, call_613267.host, call_613267.base,
                         call_613267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613267, url, valid)

proc call*(call_613268: Call_CreateBackupPlan_613256; body: JsonNode): Recallable =
  ## createBackupPlan
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ##   body: JObject (required)
  var body_613269 = newJObject()
  if body != nil:
    body_613269 = body
  result = call_613268.call(nil, nil, nil, nil, body_613269)

var createBackupPlan* = Call_CreateBackupPlan_613256(name: "createBackupPlan",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_CreateBackupPlan_613257, base: "/",
    url: url_CreateBackupPlan_613258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlans_612996 = ref object of OpenApiRestCall_612658
proc url_ListBackupPlans_612998(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlans_612997(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   includeDeleted: JBool
  ##                 : A Boolean value with a default value of <code>FALSE</code> that returns deleted backup plans when set to <code>TRUE</code>.
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613110 = query.getOrDefault("nextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "nextToken", valid_613110
  var valid_613111 = query.getOrDefault("MaxResults")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "MaxResults", valid_613111
  var valid_613112 = query.getOrDefault("NextToken")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "NextToken", valid_613112
  var valid_613113 = query.getOrDefault("includeDeleted")
  valid_613113 = validateParameter(valid_613113, JBool, required = false, default = nil)
  if valid_613113 != nil:
    section.add "includeDeleted", valid_613113
  var valid_613114 = query.getOrDefault("maxResults")
  valid_613114 = validateParameter(valid_613114, JInt, required = false, default = nil)
  if valid_613114 != nil:
    section.add "maxResults", valid_613114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613115 = header.getOrDefault("X-Amz-Signature")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Signature", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Content-Sha256", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Date")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Date", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Credential")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Credential", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Security-Token")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Security-Token", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Algorithm")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Algorithm", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-SignedHeaders", valid_613121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613144: Call_ListBackupPlans_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  let valid = call_613144.validator(path, query, header, formData, body)
  let scheme = call_613144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613144.url(scheme.get, call_613144.host, call_613144.base,
                         call_613144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613144, url, valid)

proc call*(call_613215: Call_ListBackupPlans_612996; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; includeDeleted: bool = false;
          maxResults: int = 0): Recallable =
  ## listBackupPlans
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   includeDeleted: bool
  ##                 : A Boolean value with a default value of <code>FALSE</code> that returns deleted backup plans when set to <code>TRUE</code>.
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_613216 = newJObject()
  add(query_613216, "nextToken", newJString(nextToken))
  add(query_613216, "MaxResults", newJString(MaxResults))
  add(query_613216, "NextToken", newJString(NextToken))
  add(query_613216, "includeDeleted", newJBool(includeDeleted))
  add(query_613216, "maxResults", newJInt(maxResults))
  result = call_613215.call(nil, query_613216, nil, nil, nil)

var listBackupPlans* = Call_ListBackupPlans_612996(name: "listBackupPlans",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_ListBackupPlans_612997, base: "/", url: url_ListBackupPlans_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupSelection_613303 = ref object of OpenApiRestCall_612658
proc url_CreateBackupSelection_613305(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackupSelection_613304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613306 = path.getOrDefault("backupPlanId")
  valid_613306 = validateParameter(valid_613306, JString, required = true,
                                 default = nil)
  if valid_613306 != nil:
    section.add "backupPlanId", valid_613306
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613315: Call_CreateBackupSelection_613303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  let valid = call_613315.validator(path, query, header, formData, body)
  let scheme = call_613315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613315.url(scheme.get, call_613315.host, call_613315.base,
                         call_613315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613315, url, valid)

proc call*(call_613316: Call_CreateBackupSelection_613303; backupPlanId: string;
          body: JsonNode): Recallable =
  ## createBackupSelection
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  ##   body: JObject (required)
  var path_613317 = newJObject()
  var body_613318 = newJObject()
  add(path_613317, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_613318 = body
  result = call_613316.call(path_613317, nil, nil, nil, body_613318)

var createBackupSelection* = Call_CreateBackupSelection_613303(
    name: "createBackupSelection", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_CreateBackupSelection_613304, base: "/",
    url: url_CreateBackupSelection_613305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupSelections_613270 = ref object of OpenApiRestCall_612658
proc url_ListBackupSelections_613272(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackupSelections_613271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613287 = path.getOrDefault("backupPlanId")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "backupPlanId", valid_613287
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613288 = query.getOrDefault("nextToken")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "nextToken", valid_613288
  var valid_613289 = query.getOrDefault("MaxResults")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "MaxResults", valid_613289
  var valid_613290 = query.getOrDefault("NextToken")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "NextToken", valid_613290
  var valid_613291 = query.getOrDefault("maxResults")
  valid_613291 = validateParameter(valid_613291, JInt, required = false, default = nil)
  if valid_613291 != nil:
    section.add "maxResults", valid_613291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613292 = header.getOrDefault("X-Amz-Signature")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Signature", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Content-Sha256", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Date")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Date", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Credential")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Credential", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Security-Token")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Security-Token", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Algorithm")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Algorithm", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-SignedHeaders", valid_613298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613299: Call_ListBackupSelections_613270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  let valid = call_613299.validator(path, query, header, formData, body)
  let scheme = call_613299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613299.url(scheme.get, call_613299.host, call_613299.base,
                         call_613299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613299, url, valid)

proc call*(call_613300: Call_ListBackupSelections_613270; backupPlanId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBackupSelections
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_613301 = newJObject()
  var query_613302 = newJObject()
  add(query_613302, "nextToken", newJString(nextToken))
  add(query_613302, "MaxResults", newJString(MaxResults))
  add(query_613302, "NextToken", newJString(NextToken))
  add(path_613301, "backupPlanId", newJString(backupPlanId))
  add(query_613302, "maxResults", newJInt(maxResults))
  result = call_613300.call(path_613301, query_613302, nil, nil, nil)

var listBackupSelections* = Call_ListBackupSelections_613270(
    name: "listBackupSelections", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_ListBackupSelections_613271, base: "/",
    url: url_ListBackupSelections_613272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupVault_613333 = ref object of OpenApiRestCall_612658
proc url_CreateBackupVault_613335(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBackupVault_613334(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613336 = path.getOrDefault("backupVaultName")
  valid_613336 = validateParameter(valid_613336, JString, required = true,
                                 default = nil)
  if valid_613336 != nil:
    section.add "backupVaultName", valid_613336
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613337 = header.getOrDefault("X-Amz-Signature")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Signature", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Content-Sha256", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Date")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Date", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Credential")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Credential", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Security-Token")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Security-Token", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Algorithm")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Algorithm", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-SignedHeaders", valid_613343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613345: Call_CreateBackupVault_613333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  let valid = call_613345.validator(path, query, header, formData, body)
  let scheme = call_613345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613345.url(scheme.get, call_613345.host, call_613345.base,
                         call_613345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613345, url, valid)

proc call*(call_613346: Call_CreateBackupVault_613333; backupVaultName: string;
          body: JsonNode): Recallable =
  ## createBackupVault
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_613347 = newJObject()
  var body_613348 = newJObject()
  add(path_613347, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_613348 = body
  result = call_613346.call(path_613347, nil, nil, nil, body_613348)

var createBackupVault* = Call_CreateBackupVault_613333(name: "createBackupVault",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_CreateBackupVault_613334, base: "/",
    url: url_CreateBackupVault_613335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupVault_613319 = ref object of OpenApiRestCall_612658
proc url_DescribeBackupVault_613321(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBackupVault_613320(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613322 = path.getOrDefault("backupVaultName")
  valid_613322 = validateParameter(valid_613322, JString, required = true,
                                 default = nil)
  if valid_613322 != nil:
    section.add "backupVaultName", valid_613322
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613323 = header.getOrDefault("X-Amz-Signature")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Signature", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Content-Sha256", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Date")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Date", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Credential")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Credential", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Security-Token")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Security-Token", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Algorithm")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Algorithm", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-SignedHeaders", valid_613329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613330: Call_DescribeBackupVault_613319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  let valid = call_613330.validator(path, query, header, formData, body)
  let scheme = call_613330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613330.url(scheme.get, call_613330.host, call_613330.base,
                         call_613330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613330, url, valid)

proc call*(call_613331: Call_DescribeBackupVault_613319; backupVaultName: string): Recallable =
  ## describeBackupVault
  ## Returns metadata about a backup vault specified by its name.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_613332 = newJObject()
  add(path_613332, "backupVaultName", newJString(backupVaultName))
  result = call_613331.call(path_613332, nil, nil, nil, nil)

var describeBackupVault* = Call_DescribeBackupVault_613319(
    name: "describeBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DescribeBackupVault_613320, base: "/",
    url: url_DescribeBackupVault_613321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVault_613349 = ref object of OpenApiRestCall_612658
proc url_DeleteBackupVault_613351(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVault_613350(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613352 = path.getOrDefault("backupVaultName")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "backupVaultName", valid_613352
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613353 = header.getOrDefault("X-Amz-Signature")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Signature", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Content-Sha256", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Date")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Date", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Credential")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Credential", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Security-Token")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Security-Token", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Algorithm")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Algorithm", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-SignedHeaders", valid_613359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_DeleteBackupVault_613349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_DeleteBackupVault_613349; backupVaultName: string): Recallable =
  ## deleteBackupVault
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_613362 = newJObject()
  add(path_613362, "backupVaultName", newJString(backupVaultName))
  result = call_613361.call(path_613362, nil, nil, nil, nil)

var deleteBackupVault* = Call_DeleteBackupVault_613349(name: "deleteBackupVault",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_DeleteBackupVault_613350, base: "/",
    url: url_DeleteBackupVault_613351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBackupPlan_613363 = ref object of OpenApiRestCall_612658
proc url_UpdateBackupPlan_613365(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateBackupPlan_613364(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613366 = path.getOrDefault("backupPlanId")
  valid_613366 = validateParameter(valid_613366, JString, required = true,
                                 default = nil)
  if valid_613366 != nil:
    section.add "backupPlanId", valid_613366
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613367 = header.getOrDefault("X-Amz-Signature")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Signature", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Content-Sha256", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Date")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Date", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Credential")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Credential", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Security-Token")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Security-Token", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Algorithm")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Algorithm", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-SignedHeaders", valid_613373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613375: Call_UpdateBackupPlan_613363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  let valid = call_613375.validator(path, query, header, formData, body)
  let scheme = call_613375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613375.url(scheme.get, call_613375.host, call_613375.base,
                         call_613375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613375, url, valid)

proc call*(call_613376: Call_UpdateBackupPlan_613363; backupPlanId: string;
          body: JsonNode): Recallable =
  ## updateBackupPlan
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   body: JObject (required)
  var path_613377 = newJObject()
  var body_613378 = newJObject()
  add(path_613377, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_613378 = body
  result = call_613376.call(path_613377, nil, nil, nil, body_613378)

var updateBackupPlan* = Call_UpdateBackupPlan_613363(name: "updateBackupPlan",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_UpdateBackupPlan_613364,
    base: "/", url: url_UpdateBackupPlan_613365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupPlan_613379 = ref object of OpenApiRestCall_612658
proc url_DeleteBackupPlan_613381(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupPlan_613380(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613382 = path.getOrDefault("backupPlanId")
  valid_613382 = validateParameter(valid_613382, JString, required = true,
                                 default = nil)
  if valid_613382 != nil:
    section.add "backupPlanId", valid_613382
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613383 = header.getOrDefault("X-Amz-Signature")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Signature", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Content-Sha256", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Date")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Date", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Credential")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Credential", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Security-Token")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Security-Token", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Algorithm")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Algorithm", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-SignedHeaders", valid_613389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613390: Call_DeleteBackupPlan_613379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  let valid = call_613390.validator(path, query, header, formData, body)
  let scheme = call_613390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613390.url(scheme.get, call_613390.host, call_613390.base,
                         call_613390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613390, url, valid)

proc call*(call_613391: Call_DeleteBackupPlan_613379; backupPlanId: string): Recallable =
  ## deleteBackupPlan
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_613392 = newJObject()
  add(path_613392, "backupPlanId", newJString(backupPlanId))
  result = call_613391.call(path_613392, nil, nil, nil, nil)

var deleteBackupPlan* = Call_DeleteBackupPlan_613379(name: "deleteBackupPlan",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_DeleteBackupPlan_613380,
    base: "/", url: url_DeleteBackupPlan_613381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupSelection_613393 = ref object of OpenApiRestCall_612658
proc url_GetBackupSelection_613395(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  assert "selectionId" in path, "`selectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/"),
               (kind: VariableSegment, value: "selectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupSelection_613394(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: JString (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613396 = path.getOrDefault("backupPlanId")
  valid_613396 = validateParameter(valid_613396, JString, required = true,
                                 default = nil)
  if valid_613396 != nil:
    section.add "backupPlanId", valid_613396
  var valid_613397 = path.getOrDefault("selectionId")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "selectionId", valid_613397
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613398 = header.getOrDefault("X-Amz-Signature")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Signature", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Content-Sha256", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Date")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Date", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Credential")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Credential", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Security-Token")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Security-Token", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Algorithm")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Algorithm", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-SignedHeaders", valid_613404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613405: Call_GetBackupSelection_613393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  let valid = call_613405.validator(path, query, header, formData, body)
  let scheme = call_613405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613405.url(scheme.get, call_613405.host, call_613405.base,
                         call_613405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613405, url, valid)

proc call*(call_613406: Call_GetBackupSelection_613393; backupPlanId: string;
          selectionId: string): Recallable =
  ## getBackupSelection
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_613407 = newJObject()
  add(path_613407, "backupPlanId", newJString(backupPlanId))
  add(path_613407, "selectionId", newJString(selectionId))
  result = call_613406.call(path_613407, nil, nil, nil, nil)

var getBackupSelection* = Call_GetBackupSelection_613393(
    name: "getBackupSelection", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_GetBackupSelection_613394, base: "/",
    url: url_GetBackupSelection_613395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupSelection_613408 = ref object of OpenApiRestCall_612658
proc url_DeleteBackupSelection_613410(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  assert "selectionId" in path, "`selectionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/selections/"),
               (kind: VariableSegment, value: "selectionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupSelection_613409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: JString (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613411 = path.getOrDefault("backupPlanId")
  valid_613411 = validateParameter(valid_613411, JString, required = true,
                                 default = nil)
  if valid_613411 != nil:
    section.add "backupPlanId", valid_613411
  var valid_613412 = path.getOrDefault("selectionId")
  valid_613412 = validateParameter(valid_613412, JString, required = true,
                                 default = nil)
  if valid_613412 != nil:
    section.add "selectionId", valid_613412
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613413 = header.getOrDefault("X-Amz-Signature")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Signature", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Content-Sha256", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Date")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Date", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Credential")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Credential", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Security-Token")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Security-Token", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Algorithm")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Algorithm", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-SignedHeaders", valid_613419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613420: Call_DeleteBackupSelection_613408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  let valid = call_613420.validator(path, query, header, formData, body)
  let scheme = call_613420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613420.url(scheme.get, call_613420.host, call_613420.base,
                         call_613420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613420, url, valid)

proc call*(call_613421: Call_DeleteBackupSelection_613408; backupPlanId: string;
          selectionId: string): Recallable =
  ## deleteBackupSelection
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_613422 = newJObject()
  add(path_613422, "backupPlanId", newJString(backupPlanId))
  add(path_613422, "selectionId", newJString(selectionId))
  result = call_613421.call(path_613422, nil, nil, nil, nil)

var deleteBackupSelection* = Call_DeleteBackupSelection_613408(
    name: "deleteBackupSelection", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_DeleteBackupSelection_613409, base: "/",
    url: url_DeleteBackupSelection_613410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultAccessPolicy_613437 = ref object of OpenApiRestCall_612658
proc url_PutBackupVaultAccessPolicy_613439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBackupVaultAccessPolicy_613438(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613440 = path.getOrDefault("backupVaultName")
  valid_613440 = validateParameter(valid_613440, JString, required = true,
                                 default = nil)
  if valid_613440 != nil:
    section.add "backupVaultName", valid_613440
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613441 = header.getOrDefault("X-Amz-Signature")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Signature", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Content-Sha256", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Date")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Date", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Credential")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Credential", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Security-Token")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Security-Token", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Algorithm")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Algorithm", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-SignedHeaders", valid_613447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613449: Call_PutBackupVaultAccessPolicy_613437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  let valid = call_613449.validator(path, query, header, formData, body)
  let scheme = call_613449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613449.url(scheme.get, call_613449.host, call_613449.base,
                         call_613449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613449, url, valid)

proc call*(call_613450: Call_PutBackupVaultAccessPolicy_613437;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultAccessPolicy
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_613451 = newJObject()
  var body_613452 = newJObject()
  add(path_613451, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_613452 = body
  result = call_613450.call(path_613451, nil, nil, nil, body_613452)

var putBackupVaultAccessPolicy* = Call_PutBackupVaultAccessPolicy_613437(
    name: "putBackupVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_PutBackupVaultAccessPolicy_613438, base: "/",
    url: url_PutBackupVaultAccessPolicy_613439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultAccessPolicy_613423 = ref object of OpenApiRestCall_612658
proc url_GetBackupVaultAccessPolicy_613425(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupVaultAccessPolicy_613424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613426 = path.getOrDefault("backupVaultName")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = nil)
  if valid_613426 != nil:
    section.add "backupVaultName", valid_613426
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613434: Call_GetBackupVaultAccessPolicy_613423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  let valid = call_613434.validator(path, query, header, formData, body)
  let scheme = call_613434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613434.url(scheme.get, call_613434.host, call_613434.base,
                         call_613434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613434, url, valid)

proc call*(call_613435: Call_GetBackupVaultAccessPolicy_613423;
          backupVaultName: string): Recallable =
  ## getBackupVaultAccessPolicy
  ## Returns the access policy document that is associated with the named backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_613436 = newJObject()
  add(path_613436, "backupVaultName", newJString(backupVaultName))
  result = call_613435.call(path_613436, nil, nil, nil, nil)

var getBackupVaultAccessPolicy* = Call_GetBackupVaultAccessPolicy_613423(
    name: "getBackupVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_GetBackupVaultAccessPolicy_613424, base: "/",
    url: url_GetBackupVaultAccessPolicy_613425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultAccessPolicy_613453 = ref object of OpenApiRestCall_612658
proc url_DeleteBackupVaultAccessPolicy_613455(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/access-policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVaultAccessPolicy_613454(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613456 = path.getOrDefault("backupVaultName")
  valid_613456 = validateParameter(valid_613456, JString, required = true,
                                 default = nil)
  if valid_613456 != nil:
    section.add "backupVaultName", valid_613456
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613457 = header.getOrDefault("X-Amz-Signature")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Signature", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Content-Sha256", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Date")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Date", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Credential")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Credential", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Security-Token")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Security-Token", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Algorithm")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Algorithm", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-SignedHeaders", valid_613463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613464: Call_DeleteBackupVaultAccessPolicy_613453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  let valid = call_613464.validator(path, query, header, formData, body)
  let scheme = call_613464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613464.url(scheme.get, call_613464.host, call_613464.base,
                         call_613464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613464, url, valid)

proc call*(call_613465: Call_DeleteBackupVaultAccessPolicy_613453;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultAccessPolicy
  ## Deletes the policy document that manages permissions on a backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_613466 = newJObject()
  add(path_613466, "backupVaultName", newJString(backupVaultName))
  result = call_613465.call(path_613466, nil, nil, nil, nil)

var deleteBackupVaultAccessPolicy* = Call_DeleteBackupVaultAccessPolicy_613453(
    name: "deleteBackupVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_DeleteBackupVaultAccessPolicy_613454, base: "/",
    url: url_DeleteBackupVaultAccessPolicy_613455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultNotifications_613481 = ref object of OpenApiRestCall_612658
proc url_PutBackupVaultNotifications_613483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBackupVaultNotifications_613482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613484 = path.getOrDefault("backupVaultName")
  valid_613484 = validateParameter(valid_613484, JString, required = true,
                                 default = nil)
  if valid_613484 != nil:
    section.add "backupVaultName", valid_613484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613485 = header.getOrDefault("X-Amz-Signature")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Signature", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Content-Sha256", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Date")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Date", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Credential")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Credential", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Security-Token")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Security-Token", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Algorithm")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Algorithm", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-SignedHeaders", valid_613491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613493: Call_PutBackupVaultNotifications_613481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  let valid = call_613493.validator(path, query, header, formData, body)
  let scheme = call_613493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613493.url(scheme.get, call_613493.host, call_613493.base,
                         call_613493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613493, url, valid)

proc call*(call_613494: Call_PutBackupVaultNotifications_613481;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultNotifications
  ## Turns on notifications on a backup vault for the specified topic and events.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_613495 = newJObject()
  var body_613496 = newJObject()
  add(path_613495, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_613496 = body
  result = call_613494.call(path_613495, nil, nil, nil, body_613496)

var putBackupVaultNotifications* = Call_PutBackupVaultNotifications_613481(
    name: "putBackupVaultNotifications", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_PutBackupVaultNotifications_613482, base: "/",
    url: url_PutBackupVaultNotifications_613483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultNotifications_613467 = ref object of OpenApiRestCall_612658
proc url_GetBackupVaultNotifications_613469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupVaultNotifications_613468(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns event notifications for the specified backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613470 = path.getOrDefault("backupVaultName")
  valid_613470 = validateParameter(valid_613470, JString, required = true,
                                 default = nil)
  if valid_613470 != nil:
    section.add "backupVaultName", valid_613470
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613471 = header.getOrDefault("X-Amz-Signature")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Signature", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Content-Sha256", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Date")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Date", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Credential")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Credential", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Security-Token")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Security-Token", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Algorithm")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Algorithm", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-SignedHeaders", valid_613477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613478: Call_GetBackupVaultNotifications_613467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns event notifications for the specified backup vault.
  ## 
  let valid = call_613478.validator(path, query, header, formData, body)
  let scheme = call_613478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613478.url(scheme.get, call_613478.host, call_613478.base,
                         call_613478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613478, url, valid)

proc call*(call_613479: Call_GetBackupVaultNotifications_613467;
          backupVaultName: string): Recallable =
  ## getBackupVaultNotifications
  ## Returns event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_613480 = newJObject()
  add(path_613480, "backupVaultName", newJString(backupVaultName))
  result = call_613479.call(path_613480, nil, nil, nil, nil)

var getBackupVaultNotifications* = Call_GetBackupVaultNotifications_613467(
    name: "getBackupVaultNotifications", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_GetBackupVaultNotifications_613468, base: "/",
    url: url_GetBackupVaultNotifications_613469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultNotifications_613497 = ref object of OpenApiRestCall_612658
proc url_DeleteBackupVaultNotifications_613499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/notification-configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBackupVaultNotifications_613498(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes event notifications for the specified backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613500 = path.getOrDefault("backupVaultName")
  valid_613500 = validateParameter(valid_613500, JString, required = true,
                                 default = nil)
  if valid_613500 != nil:
    section.add "backupVaultName", valid_613500
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613501 = header.getOrDefault("X-Amz-Signature")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Signature", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Content-Sha256", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Date")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Date", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Credential")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Credential", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Security-Token")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Security-Token", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Algorithm")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Algorithm", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-SignedHeaders", valid_613507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613508: Call_DeleteBackupVaultNotifications_613497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes event notifications for the specified backup vault.
  ## 
  let valid = call_613508.validator(path, query, header, formData, body)
  let scheme = call_613508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613508.url(scheme.get, call_613508.host, call_613508.base,
                         call_613508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613508, url, valid)

proc call*(call_613509: Call_DeleteBackupVaultNotifications_613497;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultNotifications
  ## Deletes event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_613510 = newJObject()
  add(path_613510, "backupVaultName", newJString(backupVaultName))
  result = call_613509.call(path_613510, nil, nil, nil, nil)

var deleteBackupVaultNotifications* = Call_DeleteBackupVaultNotifications_613497(
    name: "deleteBackupVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_DeleteBackupVaultNotifications_613498, base: "/",
    url: url_DeleteBackupVaultNotifications_613499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecoveryPointLifecycle_613526 = ref object of OpenApiRestCall_612658
proc url_UpdateRecoveryPointLifecycle_613528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRecoveryPointLifecycle_613527(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613529 = path.getOrDefault("backupVaultName")
  valid_613529 = validateParameter(valid_613529, JString, required = true,
                                 default = nil)
  if valid_613529 != nil:
    section.add "backupVaultName", valid_613529
  var valid_613530 = path.getOrDefault("recoveryPointArn")
  valid_613530 = validateParameter(valid_613530, JString, required = true,
                                 default = nil)
  if valid_613530 != nil:
    section.add "recoveryPointArn", valid_613530
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613531 = header.getOrDefault("X-Amz-Signature")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Signature", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Content-Sha256", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Date")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Date", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Credential")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Credential", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Security-Token")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Security-Token", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Algorithm")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Algorithm", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-SignedHeaders", valid_613537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613539: Call_UpdateRecoveryPointLifecycle_613526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  let valid = call_613539.validator(path, query, header, formData, body)
  let scheme = call_613539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613539.url(scheme.get, call_613539.host, call_613539.base,
                         call_613539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613539, url, valid)

proc call*(call_613540: Call_UpdateRecoveryPointLifecycle_613526;
          backupVaultName: string; recoveryPointArn: string; body: JsonNode): Recallable =
  ## updateRecoveryPointLifecycle
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   body: JObject (required)
  var path_613541 = newJObject()
  var body_613542 = newJObject()
  add(path_613541, "backupVaultName", newJString(backupVaultName))
  add(path_613541, "recoveryPointArn", newJString(recoveryPointArn))
  if body != nil:
    body_613542 = body
  result = call_613540.call(path_613541, nil, nil, nil, body_613542)

var updateRecoveryPointLifecycle* = Call_UpdateRecoveryPointLifecycle_613526(
    name: "updateRecoveryPointLifecycle", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_UpdateRecoveryPointLifecycle_613527, base: "/",
    url: url_UpdateRecoveryPointLifecycle_613528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecoveryPoint_613511 = ref object of OpenApiRestCall_612658
proc url_DescribeRecoveryPoint_613513(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRecoveryPoint_613512(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613514 = path.getOrDefault("backupVaultName")
  valid_613514 = validateParameter(valid_613514, JString, required = true,
                                 default = nil)
  if valid_613514 != nil:
    section.add "backupVaultName", valid_613514
  var valid_613515 = path.getOrDefault("recoveryPointArn")
  valid_613515 = validateParameter(valid_613515, JString, required = true,
                                 default = nil)
  if valid_613515 != nil:
    section.add "recoveryPointArn", valid_613515
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613516 = header.getOrDefault("X-Amz-Signature")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Signature", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Content-Sha256", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Date")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Date", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Credential")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Credential", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Security-Token")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Security-Token", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Algorithm")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Algorithm", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-SignedHeaders", valid_613522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613523: Call_DescribeRecoveryPoint_613511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  let valid = call_613523.validator(path, query, header, formData, body)
  let scheme = call_613523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613523.url(scheme.get, call_613523.host, call_613523.base,
                         call_613523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613523, url, valid)

proc call*(call_613524: Call_DescribeRecoveryPoint_613511; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## describeRecoveryPoint
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_613525 = newJObject()
  add(path_613525, "backupVaultName", newJString(backupVaultName))
  add(path_613525, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_613524.call(path_613525, nil, nil, nil, nil)

var describeRecoveryPoint* = Call_DescribeRecoveryPoint_613511(
    name: "describeRecoveryPoint", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DescribeRecoveryPoint_613512, base: "/",
    url: url_DescribeRecoveryPoint_613513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRecoveryPoint_613543 = ref object of OpenApiRestCall_612658
proc url_DeleteRecoveryPoint_613545(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRecoveryPoint_613544(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613546 = path.getOrDefault("backupVaultName")
  valid_613546 = validateParameter(valid_613546, JString, required = true,
                                 default = nil)
  if valid_613546 != nil:
    section.add "backupVaultName", valid_613546
  var valid_613547 = path.getOrDefault("recoveryPointArn")
  valid_613547 = validateParameter(valid_613547, JString, required = true,
                                 default = nil)
  if valid_613547 != nil:
    section.add "recoveryPointArn", valid_613547
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613548 = header.getOrDefault("X-Amz-Signature")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Signature", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Content-Sha256", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Date")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Date", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Credential")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Credential", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Security-Token")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Security-Token", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Algorithm")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Algorithm", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-SignedHeaders", valid_613554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613555: Call_DeleteRecoveryPoint_613543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  let valid = call_613555.validator(path, query, header, formData, body)
  let scheme = call_613555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613555.url(scheme.get, call_613555.host, call_613555.base,
                         call_613555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613555, url, valid)

proc call*(call_613556: Call_DeleteRecoveryPoint_613543; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## deleteRecoveryPoint
  ## Deletes the recovery point specified by a recovery point ID.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_613557 = newJObject()
  add(path_613557, "backupVaultName", newJString(backupVaultName))
  add(path_613557, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_613556.call(path_613557, nil, nil, nil, nil)

var deleteRecoveryPoint* = Call_DeleteRecoveryPoint_613543(
    name: "deleteRecoveryPoint", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DeleteRecoveryPoint_613544, base: "/",
    url: url_DeleteRecoveryPoint_613545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBackupJob_613572 = ref object of OpenApiRestCall_612658
proc url_StopBackupJob_613574(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupJobId" in path, "`backupJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-jobs/"),
               (kind: VariableSegment, value: "backupJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopBackupJob_613573(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupJobId: JString (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupJobId` field"
  var valid_613575 = path.getOrDefault("backupJobId")
  valid_613575 = validateParameter(valid_613575, JString, required = true,
                                 default = nil)
  if valid_613575 != nil:
    section.add "backupJobId", valid_613575
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613576 = header.getOrDefault("X-Amz-Signature")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Signature", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Content-Sha256", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Date")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Date", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Credential")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Credential", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Security-Token")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Security-Token", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Algorithm")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Algorithm", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-SignedHeaders", valid_613582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613583: Call_StopBackupJob_613572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  let valid = call_613583.validator(path, query, header, formData, body)
  let scheme = call_613583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613583.url(scheme.get, call_613583.host, call_613583.base,
                         call_613583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613583, url, valid)

proc call*(call_613584: Call_StopBackupJob_613572; backupJobId: string): Recallable =
  ## stopBackupJob
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_613585 = newJObject()
  add(path_613585, "backupJobId", newJString(backupJobId))
  result = call_613584.call(path_613585, nil, nil, nil, nil)

var stopBackupJob* = Call_StopBackupJob_613572(name: "stopBackupJob",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_StopBackupJob_613573,
    base: "/", url: url_StopBackupJob_613574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupJob_613558 = ref object of OpenApiRestCall_612658
proc url_DescribeBackupJob_613560(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupJobId" in path, "`backupJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-jobs/"),
               (kind: VariableSegment, value: "backupJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeBackupJob_613559(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupJobId: JString (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupJobId` field"
  var valid_613561 = path.getOrDefault("backupJobId")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = nil)
  if valid_613561 != nil:
    section.add "backupJobId", valid_613561
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613562 = header.getOrDefault("X-Amz-Signature")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Signature", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Content-Sha256", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Date")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Date", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Credential")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Credential", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Security-Token")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Security-Token", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Algorithm")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Algorithm", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-SignedHeaders", valid_613568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613569: Call_DescribeBackupJob_613558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  let valid = call_613569.validator(path, query, header, formData, body)
  let scheme = call_613569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613569.url(scheme.get, call_613569.host, call_613569.base,
                         call_613569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613569, url, valid)

proc call*(call_613570: Call_DescribeBackupJob_613558; backupJobId: string): Recallable =
  ## describeBackupJob
  ## Returns metadata associated with creating a backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_613571 = newJObject()
  add(path_613571, "backupJobId", newJString(backupJobId))
  result = call_613570.call(path_613571, nil, nil, nil, nil)

var describeBackupJob* = Call_DescribeBackupJob_613558(name: "describeBackupJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_DescribeBackupJob_613559,
    base: "/", url: url_DescribeBackupJob_613560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyJob_613586 = ref object of OpenApiRestCall_612658
proc url_DescribeCopyJob_613588(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "copyJobId" in path, "`copyJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/copy-jobs/"),
               (kind: VariableSegment, value: "copyJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCopyJob_613587(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns metadata associated with creating a copy of a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   copyJobId: JString (required)
  ##            : Uniquely identifies a request to AWS Backup to copy a resource.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `copyJobId` field"
  var valid_613589 = path.getOrDefault("copyJobId")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = nil)
  if valid_613589 != nil:
    section.add "copyJobId", valid_613589
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613590 = header.getOrDefault("X-Amz-Signature")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Signature", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Content-Sha256", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Date")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Date", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Credential")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Credential", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Security-Token")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Security-Token", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Algorithm")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Algorithm", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-SignedHeaders", valid_613596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613597: Call_DescribeCopyJob_613586; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a copy of a resource.
  ## 
  let valid = call_613597.validator(path, query, header, formData, body)
  let scheme = call_613597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613597.url(scheme.get, call_613597.host, call_613597.base,
                         call_613597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613597, url, valid)

proc call*(call_613598: Call_DescribeCopyJob_613586; copyJobId: string): Recallable =
  ## describeCopyJob
  ## Returns metadata associated with creating a copy of a resource.
  ##   copyJobId: string (required)
  ##            : Uniquely identifies a request to AWS Backup to copy a resource.
  var path_613599 = newJObject()
  add(path_613599, "copyJobId", newJString(copyJobId))
  result = call_613598.call(path_613599, nil, nil, nil, nil)

var describeCopyJob* = Call_DescribeCopyJob_613586(name: "describeCopyJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/copy-jobs/{copyJobId}", validator: validate_DescribeCopyJob_613587,
    base: "/", url: url_DescribeCopyJob_613588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProtectedResource_613600 = ref object of OpenApiRestCall_612658
proc url_DescribeProtectedResource_613602(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProtectedResource_613601(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613603 = path.getOrDefault("resourceArn")
  valid_613603 = validateParameter(valid_613603, JString, required = true,
                                 default = nil)
  if valid_613603 != nil:
    section.add "resourceArn", valid_613603
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613604 = header.getOrDefault("X-Amz-Signature")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Signature", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Content-Sha256", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Date")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Date", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Credential")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Credential", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Security-Token")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Security-Token", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Algorithm")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Algorithm", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-SignedHeaders", valid_613610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613611: Call_DescribeProtectedResource_613600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  let valid = call_613611.validator(path, query, header, formData, body)
  let scheme = call_613611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613611.url(scheme.get, call_613611.host, call_613611.base,
                         call_613611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613611, url, valid)

proc call*(call_613612: Call_DescribeProtectedResource_613600; resourceArn: string): Recallable =
  ## describeProtectedResource
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  var path_613613 = newJObject()
  add(path_613613, "resourceArn", newJString(resourceArn))
  result = call_613612.call(path_613613, nil, nil, nil, nil)

var describeProtectedResource* = Call_DescribeProtectedResource_613600(
    name: "describeProtectedResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/{resourceArn}",
    validator: validate_DescribeProtectedResource_613601, base: "/",
    url: url_DescribeProtectedResource_613602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRestoreJob_613614 = ref object of OpenApiRestCall_612658
proc url_DescribeRestoreJob_613616(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "restoreJobId" in path, "`restoreJobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/restore-jobs/"),
               (kind: VariableSegment, value: "restoreJobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRestoreJob_613615(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   restoreJobId: JString (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `restoreJobId` field"
  var valid_613617 = path.getOrDefault("restoreJobId")
  valid_613617 = validateParameter(valid_613617, JString, required = true,
                                 default = nil)
  if valid_613617 != nil:
    section.add "restoreJobId", valid_613617
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613618 = header.getOrDefault("X-Amz-Signature")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Signature", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Content-Sha256", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Date")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Date", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Credential")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Credential", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-Security-Token")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Security-Token", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Algorithm")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Algorithm", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-SignedHeaders", valid_613624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613625: Call_DescribeRestoreJob_613614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  let valid = call_613625.validator(path, query, header, formData, body)
  let scheme = call_613625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613625.url(scheme.get, call_613625.host, call_613625.base,
                         call_613625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613625, url, valid)

proc call*(call_613626: Call_DescribeRestoreJob_613614; restoreJobId: string): Recallable =
  ## describeRestoreJob
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ##   restoreJobId: string (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  var path_613627 = newJObject()
  add(path_613627, "restoreJobId", newJString(restoreJobId))
  result = call_613626.call(path_613627, nil, nil, nil, nil)

var describeRestoreJob* = Call_DescribeRestoreJob_613614(
    name: "describeRestoreJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/restore-jobs/{restoreJobId}",
    validator: validate_DescribeRestoreJob_613615, base: "/",
    url: url_DescribeRestoreJob_613616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBackupPlanTemplate_613628 = ref object of OpenApiRestCall_612658
proc url_ExportBackupPlanTemplate_613630(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/toTemplate/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportBackupPlanTemplate_613629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613631 = path.getOrDefault("backupPlanId")
  valid_613631 = validateParameter(valid_613631, JString, required = true,
                                 default = nil)
  if valid_613631 != nil:
    section.add "backupPlanId", valid_613631
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613632 = header.getOrDefault("X-Amz-Signature")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Signature", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Content-Sha256", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Date")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Date", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Credential")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Credential", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Security-Token")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Security-Token", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Algorithm")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Algorithm", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-SignedHeaders", valid_613638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613639: Call_ExportBackupPlanTemplate_613628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  let valid = call_613639.validator(path, query, header, formData, body)
  let scheme = call_613639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613639.url(scheme.get, call_613639.host, call_613639.base,
                         call_613639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613639, url, valid)

proc call*(call_613640: Call_ExportBackupPlanTemplate_613628; backupPlanId: string): Recallable =
  ## exportBackupPlanTemplate
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_613641 = newJObject()
  add(path_613641, "backupPlanId", newJString(backupPlanId))
  result = call_613640.call(path_613641, nil, nil, nil, nil)

var exportBackupPlanTemplate* = Call_ExportBackupPlanTemplate_613628(
    name: "exportBackupPlanTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/toTemplate/",
    validator: validate_ExportBackupPlanTemplate_613629, base: "/",
    url: url_ExportBackupPlanTemplate_613630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlan_613642 = ref object of OpenApiRestCall_612658
proc url_GetBackupPlan_613644(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupPlan_613643(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613645 = path.getOrDefault("backupPlanId")
  valid_613645 = validateParameter(valid_613645, JString, required = true,
                                 default = nil)
  if valid_613645 != nil:
    section.add "backupPlanId", valid_613645
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  section = newJObject()
  var valid_613646 = query.getOrDefault("versionId")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "versionId", valid_613646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613647 = header.getOrDefault("X-Amz-Signature")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Signature", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Content-Sha256", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Date")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Date", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Credential")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Credential", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Security-Token")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Security-Token", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Algorithm")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Algorithm", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-SignedHeaders", valid_613653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613654: Call_GetBackupPlan_613642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  let valid = call_613654.validator(path, query, header, formData, body)
  let scheme = call_613654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613654.url(scheme.get, call_613654.host, call_613654.base,
                         call_613654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613654, url, valid)

proc call*(call_613655: Call_GetBackupPlan_613642; backupPlanId: string;
          versionId: string = ""): Recallable =
  ## getBackupPlan
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ##   versionId: string
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_613656 = newJObject()
  var query_613657 = newJObject()
  add(query_613657, "versionId", newJString(versionId))
  add(path_613656, "backupPlanId", newJString(backupPlanId))
  result = call_613655.call(path_613656, query_613657, nil, nil, nil)

var getBackupPlan* = Call_GetBackupPlan_613642(name: "getBackupPlan",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/", validator: validate_GetBackupPlan_613643,
    base: "/", url: url_GetBackupPlan_613644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromJSON_613658 = ref object of OpenApiRestCall_612658
proc url_GetBackupPlanFromJSON_613660(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupPlanFromJSON_613659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613661 = header.getOrDefault("X-Amz-Signature")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Signature", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Content-Sha256", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Date")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Date", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Credential")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Credential", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Security-Token")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Security-Token", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Algorithm")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Algorithm", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-SignedHeaders", valid_613667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613669: Call_GetBackupPlanFromJSON_613658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  let valid = call_613669.validator(path, query, header, formData, body)
  let scheme = call_613669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613669.url(scheme.get, call_613669.host, call_613669.base,
                         call_613669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613669, url, valid)

proc call*(call_613670: Call_GetBackupPlanFromJSON_613658; body: JsonNode): Recallable =
  ## getBackupPlanFromJSON
  ## Returns a valid JSON document specifying a backup plan or an error.
  ##   body: JObject (required)
  var body_613671 = newJObject()
  if body != nil:
    body_613671 = body
  result = call_613670.call(nil, nil, nil, nil, body_613671)

var getBackupPlanFromJSON* = Call_GetBackupPlanFromJSON_613658(
    name: "getBackupPlanFromJSON", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/template/json/toPlan",
    validator: validate_GetBackupPlanFromJSON_613659, base: "/",
    url: url_GetBackupPlanFromJSON_613660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromTemplate_613672 = ref object of OpenApiRestCall_612658
proc url_GetBackupPlanFromTemplate_613674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "templateId" in path, "`templateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/template/plans/"),
               (kind: VariableSegment, value: "templateId"),
               (kind: ConstantSegment, value: "/toPlan")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBackupPlanFromTemplate_613673(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   templateId: JString (required)
  ##             : Uniquely identifies a stored backup plan template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `templateId` field"
  var valid_613675 = path.getOrDefault("templateId")
  valid_613675 = validateParameter(valid_613675, JString, required = true,
                                 default = nil)
  if valid_613675 != nil:
    section.add "templateId", valid_613675
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613676 = header.getOrDefault("X-Amz-Signature")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Signature", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Content-Sha256", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Date")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Date", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Credential")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Credential", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Security-Token")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Security-Token", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Algorithm")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Algorithm", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-SignedHeaders", valid_613682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613683: Call_GetBackupPlanFromTemplate_613672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  let valid = call_613683.validator(path, query, header, formData, body)
  let scheme = call_613683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613683.url(scheme.get, call_613683.host, call_613683.base,
                         call_613683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613683, url, valid)

proc call*(call_613684: Call_GetBackupPlanFromTemplate_613672; templateId: string): Recallable =
  ## getBackupPlanFromTemplate
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ##   templateId: string (required)
  ##             : Uniquely identifies a stored backup plan template.
  var path_613685 = newJObject()
  add(path_613685, "templateId", newJString(templateId))
  result = call_613684.call(path_613685, nil, nil, nil, nil)

var getBackupPlanFromTemplate* = Call_GetBackupPlanFromTemplate_613672(
    name: "getBackupPlanFromTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/template/plans/{templateId}/toPlan",
    validator: validate_GetBackupPlanFromTemplate_613673, base: "/",
    url: url_GetBackupPlanFromTemplate_613674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecoveryPointRestoreMetadata_613686 = ref object of OpenApiRestCall_612658
proc url_GetRecoveryPointRestoreMetadata_613688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  assert "recoveryPointArn" in path,
        "`recoveryPointArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/"),
               (kind: VariableSegment, value: "recoveryPointArn"),
               (kind: ConstantSegment, value: "/restore-metadata")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRecoveryPointRestoreMetadata_613687(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: JString (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613689 = path.getOrDefault("backupVaultName")
  valid_613689 = validateParameter(valid_613689, JString, required = true,
                                 default = nil)
  if valid_613689 != nil:
    section.add "backupVaultName", valid_613689
  var valid_613690 = path.getOrDefault("recoveryPointArn")
  valid_613690 = validateParameter(valid_613690, JString, required = true,
                                 default = nil)
  if valid_613690 != nil:
    section.add "recoveryPointArn", valid_613690
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613691 = header.getOrDefault("X-Amz-Signature")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Signature", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Content-Sha256", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Date")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Date", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Credential")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Credential", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Security-Token")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Security-Token", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Algorithm")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Algorithm", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-SignedHeaders", valid_613697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613698: Call_GetRecoveryPointRestoreMetadata_613686;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ## 
  let valid = call_613698.validator(path, query, header, formData, body)
  let scheme = call_613698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613698.url(scheme.get, call_613698.host, call_613698.base,
                         call_613698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613698, url, valid)

proc call*(call_613699: Call_GetRecoveryPointRestoreMetadata_613686;
          backupVaultName: string; recoveryPointArn: string): Recallable =
  ## getRecoveryPointRestoreMetadata
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_613700 = newJObject()
  add(path_613700, "backupVaultName", newJString(backupVaultName))
  add(path_613700, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_613699.call(path_613700, nil, nil, nil, nil)

var getRecoveryPointRestoreMetadata* = Call_GetRecoveryPointRestoreMetadata_613686(
    name: "getRecoveryPointRestoreMetadata", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}/restore-metadata",
    validator: validate_GetRecoveryPointRestoreMetadata_613687, base: "/",
    url: url_GetRecoveryPointRestoreMetadata_613688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSupportedResourceTypes_613701 = ref object of OpenApiRestCall_612658
proc url_GetSupportedResourceTypes_613703(protocol: Scheme; host: string;
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

proc validate_GetSupportedResourceTypes_613702(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613704 = header.getOrDefault("X-Amz-Signature")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Signature", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Content-Sha256", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Date")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Date", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Credential")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Credential", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Security-Token")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Security-Token", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Algorithm")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Algorithm", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-SignedHeaders", valid_613710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613711: Call_GetSupportedResourceTypes_613701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  let valid = call_613711.validator(path, query, header, formData, body)
  let scheme = call_613711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613711.url(scheme.get, call_613711.host, call_613711.base,
                         call_613711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613711, url, valid)

proc call*(call_613712: Call_GetSupportedResourceTypes_613701): Recallable =
  ## getSupportedResourceTypes
  ## Returns the AWS resource types supported by AWS Backup.
  result = call_613712.call(nil, nil, nil, nil, nil)

var getSupportedResourceTypes* = Call_GetSupportedResourceTypes_613701(
    name: "getSupportedResourceTypes", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/supported-resource-types",
    validator: validate_GetSupportedResourceTypes_613702, base: "/",
    url: url_GetSupportedResourceTypes_613703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupJobs_613713 = ref object of OpenApiRestCall_612658
proc url_ListBackupJobs_613715(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupJobs_613714(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns metadata about your backup jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   backupVaultName: JString
  ##                  : Returns only backup jobs that will be stored in the specified backup vault. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   state: JString
  ##        : Returns only backup jobs that are in the specified state.
  ##   NextToken: JString
  ##            : Pagination token
  ##   createdAfter: JString
  ##               : Returns only backup jobs that were created after the specified date.
  ##   resourceType: JString
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>DynamoDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>Storage Gateway</code> for AWS Storage Gateway</p> </li> </ul>
  ##   createdBefore: JString
  ##                : Returns only backup jobs that were created before the specified date.
  ##   resourceArn: JString
  ##              : Returns only backup jobs that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613716 = query.getOrDefault("nextToken")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "nextToken", valid_613716
  var valid_613717 = query.getOrDefault("backupVaultName")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "backupVaultName", valid_613717
  var valid_613718 = query.getOrDefault("MaxResults")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "MaxResults", valid_613718
  var valid_613732 = query.getOrDefault("state")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_613732 != nil:
    section.add "state", valid_613732
  var valid_613733 = query.getOrDefault("NextToken")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "NextToken", valid_613733
  var valid_613734 = query.getOrDefault("createdAfter")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "createdAfter", valid_613734
  var valid_613735 = query.getOrDefault("resourceType")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "resourceType", valid_613735
  var valid_613736 = query.getOrDefault("createdBefore")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "createdBefore", valid_613736
  var valid_613737 = query.getOrDefault("resourceArn")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "resourceArn", valid_613737
  var valid_613738 = query.getOrDefault("maxResults")
  valid_613738 = validateParameter(valid_613738, JInt, required = false, default = nil)
  if valid_613738 != nil:
    section.add "maxResults", valid_613738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613739 = header.getOrDefault("X-Amz-Signature")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Signature", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Content-Sha256", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Date")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Date", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Credential")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Credential", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Security-Token")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Security-Token", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Algorithm")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Algorithm", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-SignedHeaders", valid_613745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613746: Call_ListBackupJobs_613713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your backup jobs.
  ## 
  let valid = call_613746.validator(path, query, header, formData, body)
  let scheme = call_613746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613746.url(scheme.get, call_613746.host, call_613746.base,
                         call_613746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613746, url, valid)

proc call*(call_613747: Call_ListBackupJobs_613713; nextToken: string = "";
          backupVaultName: string = ""; MaxResults: string = "";
          state: string = "CREATED"; NextToken: string = ""; createdAfter: string = "";
          resourceType: string = ""; createdBefore: string = "";
          resourceArn: string = ""; maxResults: int = 0): Recallable =
  ## listBackupJobs
  ## Returns metadata about your backup jobs.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   backupVaultName: string
  ##                  : Returns only backup jobs that will be stored in the specified backup vault. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   state: string
  ##        : Returns only backup jobs that are in the specified state.
  ##   NextToken: string
  ##            : Pagination token
  ##   createdAfter: string
  ##               : Returns only backup jobs that were created after the specified date.
  ##   resourceType: string
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>DynamoDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>Storage Gateway</code> for AWS Storage Gateway</p> </li> </ul>
  ##   createdBefore: string
  ##                : Returns only backup jobs that were created before the specified date.
  ##   resourceArn: string
  ##              : Returns only backup jobs that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_613748 = newJObject()
  add(query_613748, "nextToken", newJString(nextToken))
  add(query_613748, "backupVaultName", newJString(backupVaultName))
  add(query_613748, "MaxResults", newJString(MaxResults))
  add(query_613748, "state", newJString(state))
  add(query_613748, "NextToken", newJString(NextToken))
  add(query_613748, "createdAfter", newJString(createdAfter))
  add(query_613748, "resourceType", newJString(resourceType))
  add(query_613748, "createdBefore", newJString(createdBefore))
  add(query_613748, "resourceArn", newJString(resourceArn))
  add(query_613748, "maxResults", newJInt(maxResults))
  result = call_613747.call(nil, query_613748, nil, nil, nil)

var listBackupJobs* = Call_ListBackupJobs_613713(name: "listBackupJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup-jobs/",
    validator: validate_ListBackupJobs_613714, base: "/", url: url_ListBackupJobs_613715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanTemplates_613749 = ref object of OpenApiRestCall_612658
proc url_ListBackupPlanTemplates_613751(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlanTemplates_613750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613752 = query.getOrDefault("nextToken")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "nextToken", valid_613752
  var valid_613753 = query.getOrDefault("MaxResults")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "MaxResults", valid_613753
  var valid_613754 = query.getOrDefault("NextToken")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "NextToken", valid_613754
  var valid_613755 = query.getOrDefault("maxResults")
  valid_613755 = validateParameter(valid_613755, JInt, required = false, default = nil)
  if valid_613755 != nil:
    section.add "maxResults", valid_613755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613756 = header.getOrDefault("X-Amz-Signature")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Signature", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Content-Sha256", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Date")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Date", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Credential")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Credential", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Security-Token")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Security-Token", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Algorithm")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Algorithm", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-SignedHeaders", valid_613762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613763: Call_ListBackupPlanTemplates_613749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  let valid = call_613763.validator(path, query, header, formData, body)
  let scheme = call_613763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613763.url(scheme.get, call_613763.host, call_613763.base,
                         call_613763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613763, url, valid)

proc call*(call_613764: Call_ListBackupPlanTemplates_613749;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBackupPlanTemplates
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_613765 = newJObject()
  add(query_613765, "nextToken", newJString(nextToken))
  add(query_613765, "MaxResults", newJString(MaxResults))
  add(query_613765, "NextToken", newJString(NextToken))
  add(query_613765, "maxResults", newJInt(maxResults))
  result = call_613764.call(nil, query_613765, nil, nil, nil)

var listBackupPlanTemplates* = Call_ListBackupPlanTemplates_613749(
    name: "listBackupPlanTemplates", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/template/plans",
    validator: validate_ListBackupPlanTemplates_613750, base: "/",
    url: url_ListBackupPlanTemplates_613751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanVersions_613766 = ref object of OpenApiRestCall_612658
proc url_ListBackupPlanVersions_613768(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupPlanId" in path, "`backupPlanId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup/plans/"),
               (kind: VariableSegment, value: "backupPlanId"),
               (kind: ConstantSegment, value: "/versions/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListBackupPlanVersions_613767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupPlanId: JString (required)
  ##               : Uniquely identifies a backup plan.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupPlanId` field"
  var valid_613769 = path.getOrDefault("backupPlanId")
  valid_613769 = validateParameter(valid_613769, JString, required = true,
                                 default = nil)
  if valid_613769 != nil:
    section.add "backupPlanId", valid_613769
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613770 = query.getOrDefault("nextToken")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "nextToken", valid_613770
  var valid_613771 = query.getOrDefault("MaxResults")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "MaxResults", valid_613771
  var valid_613772 = query.getOrDefault("NextToken")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "NextToken", valid_613772
  var valid_613773 = query.getOrDefault("maxResults")
  valid_613773 = validateParameter(valid_613773, JInt, required = false, default = nil)
  if valid_613773 != nil:
    section.add "maxResults", valid_613773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613774 = header.getOrDefault("X-Amz-Signature")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Signature", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Content-Sha256", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Date")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Date", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Credential")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Credential", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Security-Token")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Security-Token", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Algorithm")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Algorithm", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-SignedHeaders", valid_613780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613781: Call_ListBackupPlanVersions_613766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  let valid = call_613781.validator(path, query, header, formData, body)
  let scheme = call_613781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613781.url(scheme.get, call_613781.host, call_613781.base,
                         call_613781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613781, url, valid)

proc call*(call_613782: Call_ListBackupPlanVersions_613766; backupPlanId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listBackupPlanVersions
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_613783 = newJObject()
  var query_613784 = newJObject()
  add(query_613784, "nextToken", newJString(nextToken))
  add(query_613784, "MaxResults", newJString(MaxResults))
  add(query_613784, "NextToken", newJString(NextToken))
  add(path_613783, "backupPlanId", newJString(backupPlanId))
  add(query_613784, "maxResults", newJInt(maxResults))
  result = call_613782.call(path_613783, query_613784, nil, nil, nil)

var listBackupPlanVersions* = Call_ListBackupPlanVersions_613766(
    name: "listBackupPlanVersions", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}/versions/",
    validator: validate_ListBackupPlanVersions_613767, base: "/",
    url: url_ListBackupPlanVersions_613768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupVaults_613785 = ref object of OpenApiRestCall_612658
proc url_ListBackupVaults_613787(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupVaults_613786(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613788 = query.getOrDefault("nextToken")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "nextToken", valid_613788
  var valid_613789 = query.getOrDefault("MaxResults")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "MaxResults", valid_613789
  var valid_613790 = query.getOrDefault("NextToken")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "NextToken", valid_613790
  var valid_613791 = query.getOrDefault("maxResults")
  valid_613791 = validateParameter(valid_613791, JInt, required = false, default = nil)
  if valid_613791 != nil:
    section.add "maxResults", valid_613791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613792 = header.getOrDefault("X-Amz-Signature")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Signature", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Content-Sha256", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Date")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Date", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Credential")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Credential", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Security-Token")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Security-Token", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Algorithm")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Algorithm", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-SignedHeaders", valid_613798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613799: Call_ListBackupVaults_613785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  let valid = call_613799.validator(path, query, header, formData, body)
  let scheme = call_613799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613799.url(scheme.get, call_613799.host, call_613799.base,
                         call_613799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613799, url, valid)

proc call*(call_613800: Call_ListBackupVaults_613785; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listBackupVaults
  ## Returns a list of recovery point storage containers along with information about them.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_613801 = newJObject()
  add(query_613801, "nextToken", newJString(nextToken))
  add(query_613801, "MaxResults", newJString(MaxResults))
  add(query_613801, "NextToken", newJString(NextToken))
  add(query_613801, "maxResults", newJInt(maxResults))
  result = call_613800.call(nil, query_613801, nil, nil, nil)

var listBackupVaults* = Call_ListBackupVaults_613785(name: "listBackupVaults",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-vaults/", validator: validate_ListBackupVaults_613786,
    base: "/", url: url_ListBackupVaults_613787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCopyJobs_613802 = ref object of OpenApiRestCall_612658
proc url_ListCopyJobs_613804(protocol: Scheme; host: string; base: string;
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

proc validate_ListCopyJobs_613803(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata about your copy jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return maxResults number of items, NextToken allows you to return more items in your list starting at the location pointed to by the next token. 
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   state: JString
  ##        : Returns only copy jobs that are in the specified state.
  ##   NextToken: JString
  ##            : Pagination token
  ##   createdAfter: JString
  ##               : Returns only copy jobs that were created after the specified date.
  ##   resourceType: JString
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>DynamoDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>Storage Gateway</code> for AWS Storage Gateway</p> </li> </ul>
  ##   destinationVaultArn: JString
  ##                      : An Amazon Resource Name (ARN) that uniquely identifies a source backup vault to copy from; for example, arn:aws:backup:us-east-1:123456789012:vault:aBackupVault. 
  ##   createdBefore: JString
  ##                : Returns only copy jobs that were created before the specified date.
  ##   resourceArn: JString
  ##              : Returns only copy jobs that match the specified resource Amazon Resource Name (ARN). 
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613805 = query.getOrDefault("nextToken")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "nextToken", valid_613805
  var valid_613806 = query.getOrDefault("MaxResults")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "MaxResults", valid_613806
  var valid_613807 = query.getOrDefault("state")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_613807 != nil:
    section.add "state", valid_613807
  var valid_613808 = query.getOrDefault("NextToken")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "NextToken", valid_613808
  var valid_613809 = query.getOrDefault("createdAfter")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "createdAfter", valid_613809
  var valid_613810 = query.getOrDefault("resourceType")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "resourceType", valid_613810
  var valid_613811 = query.getOrDefault("destinationVaultArn")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "destinationVaultArn", valid_613811
  var valid_613812 = query.getOrDefault("createdBefore")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "createdBefore", valid_613812
  var valid_613813 = query.getOrDefault("resourceArn")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "resourceArn", valid_613813
  var valid_613814 = query.getOrDefault("maxResults")
  valid_613814 = validateParameter(valid_613814, JInt, required = false, default = nil)
  if valid_613814 != nil:
    section.add "maxResults", valid_613814
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613815 = header.getOrDefault("X-Amz-Signature")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Signature", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Content-Sha256", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Date")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Date", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Credential")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Credential", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Security-Token")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Security-Token", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Algorithm")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Algorithm", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-SignedHeaders", valid_613821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613822: Call_ListCopyJobs_613802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your copy jobs.
  ## 
  let valid = call_613822.validator(path, query, header, formData, body)
  let scheme = call_613822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613822.url(scheme.get, call_613822.host, call_613822.base,
                         call_613822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613822, url, valid)

proc call*(call_613823: Call_ListCopyJobs_613802; nextToken: string = "";
          MaxResults: string = ""; state: string = "CREATED"; NextToken: string = "";
          createdAfter: string = ""; resourceType: string = "";
          destinationVaultArn: string = ""; createdBefore: string = "";
          resourceArn: string = ""; maxResults: int = 0): Recallable =
  ## listCopyJobs
  ## Returns metadata about your copy jobs.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return maxResults number of items, NextToken allows you to return more items in your list starting at the location pointed to by the next token. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   state: string
  ##        : Returns only copy jobs that are in the specified state.
  ##   NextToken: string
  ##            : Pagination token
  ##   createdAfter: string
  ##               : Returns only copy jobs that were created after the specified date.
  ##   resourceType: string
  ##               : <p>Returns only backup jobs for the specified resources:</p> <ul> <li> <p> <code>DynamoDB</code> for Amazon DynamoDB</p> </li> <li> <p> <code>EBS</code> for Amazon Elastic Block Store</p> </li> <li> <p> <code>EFS</code> for Amazon Elastic File System</p> </li> <li> <p> <code>RDS</code> for Amazon Relational Database Service</p> </li> <li> <p> <code>Storage Gateway</code> for AWS Storage Gateway</p> </li> </ul>
  ##   destinationVaultArn: string
  ##                      : An Amazon Resource Name (ARN) that uniquely identifies a source backup vault to copy from; for example, arn:aws:backup:us-east-1:123456789012:vault:aBackupVault. 
  ##   createdBefore: string
  ##                : Returns only copy jobs that were created before the specified date.
  ##   resourceArn: string
  ##              : Returns only copy jobs that match the specified resource Amazon Resource Name (ARN). 
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_613824 = newJObject()
  add(query_613824, "nextToken", newJString(nextToken))
  add(query_613824, "MaxResults", newJString(MaxResults))
  add(query_613824, "state", newJString(state))
  add(query_613824, "NextToken", newJString(NextToken))
  add(query_613824, "createdAfter", newJString(createdAfter))
  add(query_613824, "resourceType", newJString(resourceType))
  add(query_613824, "destinationVaultArn", newJString(destinationVaultArn))
  add(query_613824, "createdBefore", newJString(createdBefore))
  add(query_613824, "resourceArn", newJString(resourceArn))
  add(query_613824, "maxResults", newJInt(maxResults))
  result = call_613823.call(nil, query_613824, nil, nil, nil)

var listCopyJobs* = Call_ListCopyJobs_613802(name: "listCopyJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/copy-jobs/",
    validator: validate_ListCopyJobs_613803, base: "/", url: url_ListCopyJobs_613804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProtectedResources_613825 = ref object of OpenApiRestCall_612658
proc url_ListProtectedResources_613827(protocol: Scheme; host: string; base: string;
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

proc validate_ListProtectedResources_613826(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613828 = query.getOrDefault("nextToken")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "nextToken", valid_613828
  var valid_613829 = query.getOrDefault("MaxResults")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "MaxResults", valid_613829
  var valid_613830 = query.getOrDefault("NextToken")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "NextToken", valid_613830
  var valid_613831 = query.getOrDefault("maxResults")
  valid_613831 = validateParameter(valid_613831, JInt, required = false, default = nil)
  if valid_613831 != nil:
    section.add "maxResults", valid_613831
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613832 = header.getOrDefault("X-Amz-Signature")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Signature", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Content-Sha256", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Date")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Date", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Credential")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Credential", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Security-Token")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Security-Token", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Algorithm")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Algorithm", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-SignedHeaders", valid_613838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613839: Call_ListProtectedResources_613825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  let valid = call_613839.validator(path, query, header, formData, body)
  let scheme = call_613839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613839.url(scheme.get, call_613839.host, call_613839.base,
                         call_613839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613839, url, valid)

proc call*(call_613840: Call_ListProtectedResources_613825; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listProtectedResources
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_613841 = newJObject()
  add(query_613841, "nextToken", newJString(nextToken))
  add(query_613841, "MaxResults", newJString(MaxResults))
  add(query_613841, "NextToken", newJString(NextToken))
  add(query_613841, "maxResults", newJInt(maxResults))
  result = call_613840.call(nil, query_613841, nil, nil, nil)

var listProtectedResources* = Call_ListProtectedResources_613825(
    name: "listProtectedResources", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/",
    validator: validate_ListProtectedResources_613826, base: "/",
    url: url_ListProtectedResources_613827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByBackupVault_613842 = ref object of OpenApiRestCall_612658
proc url_ListRecoveryPointsByBackupVault_613844(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "backupVaultName" in path, "`backupVaultName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/backup-vaults/"),
               (kind: VariableSegment, value: "backupVaultName"),
               (kind: ConstantSegment, value: "/recovery-points/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecoveryPointsByBackupVault_613843(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   backupVaultName: JString (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `backupVaultName` field"
  var valid_613845 = path.getOrDefault("backupVaultName")
  valid_613845 = validateParameter(valid_613845, JString, required = true,
                                 default = nil)
  if valid_613845 != nil:
    section.add "backupVaultName", valid_613845
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   backupPlanId: JString
  ##               : Returns only recovery points that match the specified backup plan ID.
  ##   NextToken: JString
  ##            : Pagination token
  ##   createdAfter: JString
  ##               : Returns only recovery points that were created after the specified timestamp.
  ##   resourceType: JString
  ##               : Returns only recovery points that match the specified resource type.
  ##   createdBefore: JString
  ##                : Returns only recovery points that were created before the specified timestamp.
  ##   resourceArn: JString
  ##              : Returns only recovery points that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613846 = query.getOrDefault("nextToken")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "nextToken", valid_613846
  var valid_613847 = query.getOrDefault("MaxResults")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "MaxResults", valid_613847
  var valid_613848 = query.getOrDefault("backupPlanId")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "backupPlanId", valid_613848
  var valid_613849 = query.getOrDefault("NextToken")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "NextToken", valid_613849
  var valid_613850 = query.getOrDefault("createdAfter")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "createdAfter", valid_613850
  var valid_613851 = query.getOrDefault("resourceType")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "resourceType", valid_613851
  var valid_613852 = query.getOrDefault("createdBefore")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "createdBefore", valid_613852
  var valid_613853 = query.getOrDefault("resourceArn")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "resourceArn", valid_613853
  var valid_613854 = query.getOrDefault("maxResults")
  valid_613854 = validateParameter(valid_613854, JInt, required = false, default = nil)
  if valid_613854 != nil:
    section.add "maxResults", valid_613854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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
  if body != nil:
    result.add "body", body

proc call*(call_613862: Call_ListRecoveryPointsByBackupVault_613842;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  let valid = call_613862.validator(path, query, header, formData, body)
  let scheme = call_613862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613862.url(scheme.get, call_613862.host, call_613862.base,
                         call_613862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613862, url, valid)

proc call*(call_613863: Call_ListRecoveryPointsByBackupVault_613842;
          backupVaultName: string; nextToken: string = ""; MaxResults: string = "";
          backupPlanId: string = ""; NextToken: string = ""; createdAfter: string = "";
          resourceType: string = ""; createdBefore: string = "";
          resourceArn: string = ""; maxResults: int = 0): Recallable =
  ## listRecoveryPointsByBackupVault
  ## Returns detailed information about the recovery points stored in a backup vault.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   backupPlanId: string
  ##               : Returns only recovery points that match the specified backup plan ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   createdAfter: string
  ##               : Returns only recovery points that were created after the specified timestamp.
  ##   resourceType: string
  ##               : Returns only recovery points that match the specified resource type.
  ##   createdBefore: string
  ##                : Returns only recovery points that were created before the specified timestamp.
  ##   resourceArn: string
  ##              : Returns only recovery points that match the specified resource Amazon Resource Name (ARN).
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_613864 = newJObject()
  var query_613865 = newJObject()
  add(query_613865, "nextToken", newJString(nextToken))
  add(query_613865, "MaxResults", newJString(MaxResults))
  add(path_613864, "backupVaultName", newJString(backupVaultName))
  add(query_613865, "backupPlanId", newJString(backupPlanId))
  add(query_613865, "NextToken", newJString(NextToken))
  add(query_613865, "createdAfter", newJString(createdAfter))
  add(query_613865, "resourceType", newJString(resourceType))
  add(query_613865, "createdBefore", newJString(createdBefore))
  add(query_613865, "resourceArn", newJString(resourceArn))
  add(query_613865, "maxResults", newJInt(maxResults))
  result = call_613863.call(path_613864, query_613865, nil, nil, nil)

var listRecoveryPointsByBackupVault* = Call_ListRecoveryPointsByBackupVault_613842(
    name: "listRecoveryPointsByBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/recovery-points/",
    validator: validate_ListRecoveryPointsByBackupVault_613843, base: "/",
    url: url_ListRecoveryPointsByBackupVault_613844,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByResource_613866 = ref object of OpenApiRestCall_612658
proc url_ListRecoveryPointsByResource_613868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "/recovery-points/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRecoveryPointsByResource_613867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the resource type.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613869 = path.getOrDefault("resourceArn")
  valid_613869 = validateParameter(valid_613869, JString, required = true,
                                 default = nil)
  if valid_613869 != nil:
    section.add "resourceArn", valid_613869
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613870 = query.getOrDefault("nextToken")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "nextToken", valid_613870
  var valid_613871 = query.getOrDefault("MaxResults")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "MaxResults", valid_613871
  var valid_613872 = query.getOrDefault("NextToken")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "NextToken", valid_613872
  var valid_613873 = query.getOrDefault("maxResults")
  valid_613873 = validateParameter(valid_613873, JInt, required = false, default = nil)
  if valid_613873 != nil:
    section.add "maxResults", valid_613873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613874 = header.getOrDefault("X-Amz-Signature")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Signature", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Content-Sha256", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Date")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Date", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Credential")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Credential", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Security-Token")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Security-Token", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Algorithm")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Algorithm", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-SignedHeaders", valid_613880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613881: Call_ListRecoveryPointsByResource_613866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  let valid = call_613881.validator(path, query, header, formData, body)
  let scheme = call_613881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613881.url(scheme.get, call_613881.host, call_613881.base,
                         call_613881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613881, url, valid)

proc call*(call_613882: Call_ListRecoveryPointsByResource_613866;
          resourceArn: string; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRecoveryPointsByResource
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the resource type.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_613883 = newJObject()
  var query_613884 = newJObject()
  add(query_613884, "nextToken", newJString(nextToken))
  add(query_613884, "MaxResults", newJString(MaxResults))
  add(path_613883, "resourceArn", newJString(resourceArn))
  add(query_613884, "NextToken", newJString(NextToken))
  add(query_613884, "maxResults", newJInt(maxResults))
  result = call_613882.call(path_613883, query_613884, nil, nil, nil)

var listRecoveryPointsByResource* = Call_ListRecoveryPointsByResource_613866(
    name: "listRecoveryPointsByResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/resources/{resourceArn}/recovery-points/",
    validator: validate_ListRecoveryPointsByResource_613867, base: "/",
    url: url_ListRecoveryPointsByResource_613868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRestoreJobs_613885 = ref object of OpenApiRestCall_612658
proc url_ListRestoreJobs_613887(protocol: Scheme; host: string; base: string;
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

proc validate_ListRestoreJobs_613886(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613888 = query.getOrDefault("nextToken")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "nextToken", valid_613888
  var valid_613889 = query.getOrDefault("MaxResults")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "MaxResults", valid_613889
  var valid_613890 = query.getOrDefault("NextToken")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "NextToken", valid_613890
  var valid_613891 = query.getOrDefault("maxResults")
  valid_613891 = validateParameter(valid_613891, JInt, required = false, default = nil)
  if valid_613891 != nil:
    section.add "maxResults", valid_613891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613892 = header.getOrDefault("X-Amz-Signature")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Signature", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Content-Sha256", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Date")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Date", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Credential")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Credential", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Security-Token")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Security-Token", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Algorithm")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Algorithm", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-SignedHeaders", valid_613898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613899: Call_ListRestoreJobs_613885; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  let valid = call_613899.validator(path, query, header, formData, body)
  let scheme = call_613899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613899.url(scheme.get, call_613899.host, call_613899.base,
                         call_613899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613899, url, valid)

proc call*(call_613900: Call_ListRestoreJobs_613885; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRestoreJobs
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var query_613901 = newJObject()
  add(query_613901, "nextToken", newJString(nextToken))
  add(query_613901, "MaxResults", newJString(MaxResults))
  add(query_613901, "NextToken", newJString(NextToken))
  add(query_613901, "maxResults", newJInt(maxResults))
  result = call_613900.call(nil, query_613901, nil, nil, nil)

var listRestoreJobs* = Call_ListRestoreJobs_613885(name: "listRestoreJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/restore-jobs/",
    validator: validate_ListRestoreJobs_613886, base: "/", url: url_ListRestoreJobs_613887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_613902 = ref object of OpenApiRestCall_612658
proc url_ListTags_613904(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_613903(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the type of resource. Valid targets for <code>ListTags</code> are recovery points, backup plans, and backup vaults.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613905 = path.getOrDefault("resourceArn")
  valid_613905 = validateParameter(valid_613905, JString, required = true,
                                 default = nil)
  if valid_613905 != nil:
    section.add "resourceArn", valid_613905
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of items to be returned.
  section = newJObject()
  var valid_613906 = query.getOrDefault("nextToken")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "nextToken", valid_613906
  var valid_613907 = query.getOrDefault("MaxResults")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "MaxResults", valid_613907
  var valid_613908 = query.getOrDefault("NextToken")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "NextToken", valid_613908
  var valid_613909 = query.getOrDefault("maxResults")
  valid_613909 = validateParameter(valid_613909, JInt, required = false, default = nil)
  if valid_613909 != nil:
    section.add "maxResults", valid_613909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613910 = header.getOrDefault("X-Amz-Signature")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Signature", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Content-Sha256", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Date")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Date", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Credential")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Credential", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Security-Token")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Security-Token", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Algorithm")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Algorithm", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-SignedHeaders", valid_613916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613917: Call_ListTags_613902; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  let valid = call_613917.validator(path, query, header, formData, body)
  let scheme = call_613917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613917.url(scheme.get, call_613917.host, call_613917.base,
                         call_613917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613917, url, valid)

proc call*(call_613918: Call_ListTags_613902; resourceArn: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listTags
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ##   nextToken: string
  ##            : The next item following a partial list of returned items. For example, if a request is made to return <code>maxResults</code> number of items, <code>NextToken</code> allows you to return more items in your list starting at the location pointed to by the next token.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the type of resource. Valid targets for <code>ListTags</code> are recovery points, backup plans, and backup vaults.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of items to be returned.
  var path_613919 = newJObject()
  var query_613920 = newJObject()
  add(query_613920, "nextToken", newJString(nextToken))
  add(query_613920, "MaxResults", newJString(MaxResults))
  add(path_613919, "resourceArn", newJString(resourceArn))
  add(query_613920, "NextToken", newJString(NextToken))
  add(query_613920, "maxResults", newJInt(maxResults))
  result = call_613918.call(path_613919, query_613920, nil, nil, nil)

var listTags* = Call_ListTags_613902(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "backup.amazonaws.com",
                                  route: "/tags/{resourceArn}/",
                                  validator: validate_ListTags_613903, base: "/",
                                  url: url_ListTags_613904,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBackupJob_613921 = ref object of OpenApiRestCall_612658
proc url_StartBackupJob_613923(protocol: Scheme; host: string; base: string;
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

proc validate_StartBackupJob_613922(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613924 = header.getOrDefault("X-Amz-Signature")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Signature", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Content-Sha256", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Date")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Date", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Credential")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Credential", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Security-Token")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Security-Token", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Algorithm")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Algorithm", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-SignedHeaders", valid_613930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613932: Call_StartBackupJob_613921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  let valid = call_613932.validator(path, query, header, formData, body)
  let scheme = call_613932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613932.url(scheme.get, call_613932.host, call_613932.base,
                         call_613932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613932, url, valid)

proc call*(call_613933: Call_StartBackupJob_613921; body: JsonNode): Recallable =
  ## startBackupJob
  ## Starts a job to create a one-time backup of the specified resource.
  ##   body: JObject (required)
  var body_613934 = newJObject()
  if body != nil:
    body_613934 = body
  result = call_613933.call(nil, nil, nil, nil, body_613934)

var startBackupJob* = Call_StartBackupJob_613921(name: "startBackupJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup-jobs",
    validator: validate_StartBackupJob_613922, base: "/", url: url_StartBackupJob_613923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCopyJob_613935 = ref object of OpenApiRestCall_612658
proc url_StartCopyJob_613937(protocol: Scheme; host: string; base: string;
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

proc validate_StartCopyJob_613936(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a job to create a one-time copy of the specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613938 = header.getOrDefault("X-Amz-Signature")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Signature", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-Content-Sha256", valid_613939
  var valid_613940 = header.getOrDefault("X-Amz-Date")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Date", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Credential")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Credential", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-Security-Token")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Security-Token", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Algorithm")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Algorithm", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-SignedHeaders", valid_613944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613946: Call_StartCopyJob_613935; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time copy of the specified resource.
  ## 
  let valid = call_613946.validator(path, query, header, formData, body)
  let scheme = call_613946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613946.url(scheme.get, call_613946.host, call_613946.base,
                         call_613946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613946, url, valid)

proc call*(call_613947: Call_StartCopyJob_613935; body: JsonNode): Recallable =
  ## startCopyJob
  ## Starts a job to create a one-time copy of the specified resource.
  ##   body: JObject (required)
  var body_613948 = newJObject()
  if body != nil:
    body_613948 = body
  result = call_613947.call(nil, nil, nil, nil, body_613948)

var startCopyJob* = Call_StartCopyJob_613935(name: "startCopyJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/copy-jobs",
    validator: validate_StartCopyJob_613936, base: "/", url: url_StartCopyJob_613937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRestoreJob_613949 = ref object of OpenApiRestCall_612658
proc url_StartRestoreJob_613951(protocol: Scheme; host: string; base: string;
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

proc validate_StartRestoreJob_613950(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613952 = header.getOrDefault("X-Amz-Signature")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Signature", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Content-Sha256", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Date")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Date", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Credential")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Credential", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-Security-Token")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-Security-Token", valid_613956
  var valid_613957 = header.getOrDefault("X-Amz-Algorithm")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Algorithm", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-SignedHeaders", valid_613958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613960: Call_StartRestoreJob_613949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  let valid = call_613960.validator(path, query, header, formData, body)
  let scheme = call_613960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613960.url(scheme.get, call_613960.host, call_613960.base,
                         call_613960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613960, url, valid)

proc call*(call_613961: Call_StartRestoreJob_613949; body: JsonNode): Recallable =
  ## startRestoreJob
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ##   body: JObject (required)
  var body_613962 = newJObject()
  if body != nil:
    body_613962 = body
  result = call_613961.call(nil, nil, nil, nil, body_613962)

var startRestoreJob* = Call_StartRestoreJob_613949(name: "startRestoreJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/restore-jobs",
    validator: validate_StartRestoreJob_613950, base: "/", url: url_StartRestoreJob_613951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613963 = ref object of OpenApiRestCall_612658
proc url_TagResource_613965(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613964(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613966 = path.getOrDefault("resourceArn")
  valid_613966 = validateParameter(valid_613966, JString, required = true,
                                 default = nil)
  if valid_613966 != nil:
    section.add "resourceArn", valid_613966
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613967 = header.getOrDefault("X-Amz-Signature")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "X-Amz-Signature", valid_613967
  var valid_613968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "X-Amz-Content-Sha256", valid_613968
  var valid_613969 = header.getOrDefault("X-Amz-Date")
  valid_613969 = validateParameter(valid_613969, JString, required = false,
                                 default = nil)
  if valid_613969 != nil:
    section.add "X-Amz-Date", valid_613969
  var valid_613970 = header.getOrDefault("X-Amz-Credential")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "X-Amz-Credential", valid_613970
  var valid_613971 = header.getOrDefault("X-Amz-Security-Token")
  valid_613971 = validateParameter(valid_613971, JString, required = false,
                                 default = nil)
  if valid_613971 != nil:
    section.add "X-Amz-Security-Token", valid_613971
  var valid_613972 = header.getOrDefault("X-Amz-Algorithm")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-Algorithm", valid_613972
  var valid_613973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-SignedHeaders", valid_613973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613975: Call_TagResource_613963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  let valid = call_613975.validator(path, query, header, formData, body)
  let scheme = call_613975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613975.url(scheme.get, call_613975.host, call_613975.base,
                         call_613975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613975, url, valid)

proc call*(call_613976: Call_TagResource_613963; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_613977 = newJObject()
  var body_613978 = newJObject()
  add(path_613977, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613978 = body
  result = call_613976.call(path_613977, nil, nil, nil, body_613978)

var tagResource* = Call_TagResource_613963(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "backup.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613964,
                                        base: "/", url: url_TagResource_613965,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613979 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613981(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/untag/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613980(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613982 = path.getOrDefault("resourceArn")
  valid_613982 = validateParameter(valid_613982, JString, required = true,
                                 default = nil)
  if valid_613982 != nil:
    section.add "resourceArn", valid_613982
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613983 = header.getOrDefault("X-Amz-Signature")
  valid_613983 = validateParameter(valid_613983, JString, required = false,
                                 default = nil)
  if valid_613983 != nil:
    section.add "X-Amz-Signature", valid_613983
  var valid_613984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613984 = validateParameter(valid_613984, JString, required = false,
                                 default = nil)
  if valid_613984 != nil:
    section.add "X-Amz-Content-Sha256", valid_613984
  var valid_613985 = header.getOrDefault("X-Amz-Date")
  valid_613985 = validateParameter(valid_613985, JString, required = false,
                                 default = nil)
  if valid_613985 != nil:
    section.add "X-Amz-Date", valid_613985
  var valid_613986 = header.getOrDefault("X-Amz-Credential")
  valid_613986 = validateParameter(valid_613986, JString, required = false,
                                 default = nil)
  if valid_613986 != nil:
    section.add "X-Amz-Credential", valid_613986
  var valid_613987 = header.getOrDefault("X-Amz-Security-Token")
  valid_613987 = validateParameter(valid_613987, JString, required = false,
                                 default = nil)
  if valid_613987 != nil:
    section.add "X-Amz-Security-Token", valid_613987
  var valid_613988 = header.getOrDefault("X-Amz-Algorithm")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-Algorithm", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-SignedHeaders", valid_613989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613991: Call_UntagResource_613979; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  let valid = call_613991.validator(path, query, header, formData, body)
  let scheme = call_613991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613991.url(scheme.get, call_613991.host, call_613991.base,
                         call_613991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613991, url, valid)

proc call*(call_613992: Call_UntagResource_613979; resourceArn: string;
          body: JsonNode): Recallable =
  ## untagResource
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_613993 = newJObject()
  var body_613994 = newJObject()
  add(path_613993, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613994 = body
  result = call_613992.call(path_613993, nil, nil, nil, body_613994)

var untagResource* = Call_UntagResource_613979(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/untag/{resourceArn}", validator: validate_UntagResource_613980,
    base: "/", url: url_UntagResource_613981, schemes: {Scheme.Https, Scheme.Http})
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
