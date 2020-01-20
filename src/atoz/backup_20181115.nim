
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_CreateBackupPlan_606187 = ref object of OpenApiRestCall_605589
proc url_CreateBackupPlan_606189(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupPlan_606188(path: JsonNode; query: JsonNode;
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
  var valid_606190 = header.getOrDefault("X-Amz-Signature")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Signature", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Content-Sha256", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Date")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Date", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Credential")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Credential", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Security-Token")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Security-Token", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Algorithm")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Algorithm", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-SignedHeaders", valid_606196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606198: Call_CreateBackupPlan_606187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ## 
  let valid = call_606198.validator(path, query, header, formData, body)
  let scheme = call_606198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606198.url(scheme.get, call_606198.host, call_606198.base,
                         call_606198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606198, url, valid)

proc call*(call_606199: Call_CreateBackupPlan_606187; body: JsonNode): Recallable =
  ## createBackupPlan
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ##   body: JObject (required)
  var body_606200 = newJObject()
  if body != nil:
    body_606200 = body
  result = call_606199.call(nil, nil, nil, nil, body_606200)

var createBackupPlan* = Call_CreateBackupPlan_606187(name: "createBackupPlan",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_CreateBackupPlan_606188, base: "/",
    url: url_CreateBackupPlan_606189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlans_605927 = ref object of OpenApiRestCall_605589
proc url_ListBackupPlans_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlans_605928(path: JsonNode; query: JsonNode;
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
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606042 = query.getOrDefault("MaxResults")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "MaxResults", valid_606042
  var valid_606043 = query.getOrDefault("NextToken")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "NextToken", valid_606043
  var valid_606044 = query.getOrDefault("includeDeleted")
  valid_606044 = validateParameter(valid_606044, JBool, required = false, default = nil)
  if valid_606044 != nil:
    section.add "includeDeleted", valid_606044
  var valid_606045 = query.getOrDefault("maxResults")
  valid_606045 = validateParameter(valid_606045, JInt, required = false, default = nil)
  if valid_606045 != nil:
    section.add "maxResults", valid_606045
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
  var valid_606046 = header.getOrDefault("X-Amz-Signature")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Signature", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Content-Sha256", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Date")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Date", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Credential")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Credential", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Security-Token")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Security-Token", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Algorithm")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Algorithm", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-SignedHeaders", valid_606052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606075: Call_ListBackupPlans_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  let valid = call_606075.validator(path, query, header, formData, body)
  let scheme = call_606075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606075.url(scheme.get, call_606075.host, call_606075.base,
                         call_606075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606075, url, valid)

proc call*(call_606146: Call_ListBackupPlans_605927; nextToken: string = "";
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
  var query_606147 = newJObject()
  add(query_606147, "nextToken", newJString(nextToken))
  add(query_606147, "MaxResults", newJString(MaxResults))
  add(query_606147, "NextToken", newJString(NextToken))
  add(query_606147, "includeDeleted", newJBool(includeDeleted))
  add(query_606147, "maxResults", newJInt(maxResults))
  result = call_606146.call(nil, query_606147, nil, nil, nil)

var listBackupPlans* = Call_ListBackupPlans_605927(name: "listBackupPlans",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_ListBackupPlans_605928, base: "/", url: url_ListBackupPlans_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupSelection_606234 = ref object of OpenApiRestCall_605589
proc url_CreateBackupSelection_606236(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupSelection_606235(path: JsonNode; query: JsonNode;
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
  var valid_606237 = path.getOrDefault("backupPlanId")
  valid_606237 = validateParameter(valid_606237, JString, required = true,
                                 default = nil)
  if valid_606237 != nil:
    section.add "backupPlanId", valid_606237
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
  var valid_606238 = header.getOrDefault("X-Amz-Signature")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Signature", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Content-Sha256", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Date")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Date", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Credential")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Credential", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Security-Token")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Security-Token", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Algorithm")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Algorithm", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-SignedHeaders", valid_606244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606246: Call_CreateBackupSelection_606234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  let valid = call_606246.validator(path, query, header, formData, body)
  let scheme = call_606246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606246.url(scheme.get, call_606246.host, call_606246.base,
                         call_606246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606246, url, valid)

proc call*(call_606247: Call_CreateBackupSelection_606234; backupPlanId: string;
          body: JsonNode): Recallable =
  ## createBackupSelection
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  ##   body: JObject (required)
  var path_606248 = newJObject()
  var body_606249 = newJObject()
  add(path_606248, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_606249 = body
  result = call_606247.call(path_606248, nil, nil, nil, body_606249)

var createBackupSelection* = Call_CreateBackupSelection_606234(
    name: "createBackupSelection", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_CreateBackupSelection_606235, base: "/",
    url: url_CreateBackupSelection_606236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupSelections_606201 = ref object of OpenApiRestCall_605589
proc url_ListBackupSelections_606203(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupSelections_606202(path: JsonNode; query: JsonNode;
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
  var valid_606218 = path.getOrDefault("backupPlanId")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "backupPlanId", valid_606218
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
  var valid_606219 = query.getOrDefault("nextToken")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "nextToken", valid_606219
  var valid_606220 = query.getOrDefault("MaxResults")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "MaxResults", valid_606220
  var valid_606221 = query.getOrDefault("NextToken")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "NextToken", valid_606221
  var valid_606222 = query.getOrDefault("maxResults")
  valid_606222 = validateParameter(valid_606222, JInt, required = false, default = nil)
  if valid_606222 != nil:
    section.add "maxResults", valid_606222
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
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Security-Token")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Security-Token", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Algorithm")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Algorithm", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-SignedHeaders", valid_606229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606230: Call_ListBackupSelections_606201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  let valid = call_606230.validator(path, query, header, formData, body)
  let scheme = call_606230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606230.url(scheme.get, call_606230.host, call_606230.base,
                         call_606230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606230, url, valid)

proc call*(call_606231: Call_ListBackupSelections_606201; backupPlanId: string;
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
  var path_606232 = newJObject()
  var query_606233 = newJObject()
  add(query_606233, "nextToken", newJString(nextToken))
  add(query_606233, "MaxResults", newJString(MaxResults))
  add(query_606233, "NextToken", newJString(NextToken))
  add(path_606232, "backupPlanId", newJString(backupPlanId))
  add(query_606233, "maxResults", newJInt(maxResults))
  result = call_606231.call(path_606232, query_606233, nil, nil, nil)

var listBackupSelections* = Call_ListBackupSelections_606201(
    name: "listBackupSelections", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_ListBackupSelections_606202, base: "/",
    url: url_ListBackupSelections_606203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupVault_606264 = ref object of OpenApiRestCall_605589
proc url_CreateBackupVault_606266(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupVault_606265(path: JsonNode; query: JsonNode;
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
  var valid_606267 = path.getOrDefault("backupVaultName")
  valid_606267 = validateParameter(valid_606267, JString, required = true,
                                 default = nil)
  if valid_606267 != nil:
    section.add "backupVaultName", valid_606267
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
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606276: Call_CreateBackupVault_606264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  let valid = call_606276.validator(path, query, header, formData, body)
  let scheme = call_606276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606276.url(scheme.get, call_606276.host, call_606276.base,
                         call_606276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606276, url, valid)

proc call*(call_606277: Call_CreateBackupVault_606264; backupVaultName: string;
          body: JsonNode): Recallable =
  ## createBackupVault
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_606278 = newJObject()
  var body_606279 = newJObject()
  add(path_606278, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_606279 = body
  result = call_606277.call(path_606278, nil, nil, nil, body_606279)

var createBackupVault* = Call_CreateBackupVault_606264(name: "createBackupVault",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_CreateBackupVault_606265, base: "/",
    url: url_CreateBackupVault_606266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupVault_606250 = ref object of OpenApiRestCall_605589
proc url_DescribeBackupVault_606252(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBackupVault_606251(path: JsonNode; query: JsonNode;
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
  var valid_606253 = path.getOrDefault("backupVaultName")
  valid_606253 = validateParameter(valid_606253, JString, required = true,
                                 default = nil)
  if valid_606253 != nil:
    section.add "backupVaultName", valid_606253
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
  var valid_606254 = header.getOrDefault("X-Amz-Signature")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Signature", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Content-Sha256", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Date")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Date", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Credential")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Credential", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Security-Token")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Security-Token", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Algorithm")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Algorithm", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-SignedHeaders", valid_606260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606261: Call_DescribeBackupVault_606250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  let valid = call_606261.validator(path, query, header, formData, body)
  let scheme = call_606261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606261.url(scheme.get, call_606261.host, call_606261.base,
                         call_606261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606261, url, valid)

proc call*(call_606262: Call_DescribeBackupVault_606250; backupVaultName: string): Recallable =
  ## describeBackupVault
  ## Returns metadata about a backup vault specified by its name.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_606263 = newJObject()
  add(path_606263, "backupVaultName", newJString(backupVaultName))
  result = call_606262.call(path_606263, nil, nil, nil, nil)

var describeBackupVault* = Call_DescribeBackupVault_606250(
    name: "describeBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DescribeBackupVault_606251, base: "/",
    url: url_DescribeBackupVault_606252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVault_606280 = ref object of OpenApiRestCall_605589
proc url_DeleteBackupVault_606282(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupVault_606281(path: JsonNode; query: JsonNode;
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
  var valid_606283 = path.getOrDefault("backupVaultName")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "backupVaultName", valid_606283
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
  var valid_606284 = header.getOrDefault("X-Amz-Signature")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Signature", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Content-Sha256", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Date")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Date", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Credential")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Credential", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Security-Token")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Security-Token", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Algorithm")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Algorithm", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-SignedHeaders", valid_606290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_DeleteBackupVault_606280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_DeleteBackupVault_606280; backupVaultName: string): Recallable =
  ## deleteBackupVault
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_606293 = newJObject()
  add(path_606293, "backupVaultName", newJString(backupVaultName))
  result = call_606292.call(path_606293, nil, nil, nil, nil)

var deleteBackupVault* = Call_DeleteBackupVault_606280(name: "deleteBackupVault",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_DeleteBackupVault_606281, base: "/",
    url: url_DeleteBackupVault_606282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBackupPlan_606294 = ref object of OpenApiRestCall_605589
proc url_UpdateBackupPlan_606296(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBackupPlan_606295(path: JsonNode; query: JsonNode;
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
  var valid_606297 = path.getOrDefault("backupPlanId")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = nil)
  if valid_606297 != nil:
    section.add "backupPlanId", valid_606297
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
  var valid_606298 = header.getOrDefault("X-Amz-Signature")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Signature", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Content-Sha256", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Date")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Date", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Credential")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Credential", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Security-Token")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Security-Token", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Algorithm")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Algorithm", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-SignedHeaders", valid_606304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606306: Call_UpdateBackupPlan_606294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  let valid = call_606306.validator(path, query, header, formData, body)
  let scheme = call_606306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606306.url(scheme.get, call_606306.host, call_606306.base,
                         call_606306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606306, url, valid)

proc call*(call_606307: Call_UpdateBackupPlan_606294; backupPlanId: string;
          body: JsonNode): Recallable =
  ## updateBackupPlan
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   body: JObject (required)
  var path_606308 = newJObject()
  var body_606309 = newJObject()
  add(path_606308, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_606309 = body
  result = call_606307.call(path_606308, nil, nil, nil, body_606309)

var updateBackupPlan* = Call_UpdateBackupPlan_606294(name: "updateBackupPlan",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_UpdateBackupPlan_606295,
    base: "/", url: url_UpdateBackupPlan_606296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupPlan_606310 = ref object of OpenApiRestCall_605589
proc url_DeleteBackupPlan_606312(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupPlan_606311(path: JsonNode; query: JsonNode;
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
  var valid_606313 = path.getOrDefault("backupPlanId")
  valid_606313 = validateParameter(valid_606313, JString, required = true,
                                 default = nil)
  if valid_606313 != nil:
    section.add "backupPlanId", valid_606313
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
  var valid_606314 = header.getOrDefault("X-Amz-Signature")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Signature", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Content-Sha256", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Date")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Date", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Credential")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Credential", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Security-Token")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Security-Token", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Algorithm")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Algorithm", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-SignedHeaders", valid_606320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606321: Call_DeleteBackupPlan_606310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  let valid = call_606321.validator(path, query, header, formData, body)
  let scheme = call_606321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606321.url(scheme.get, call_606321.host, call_606321.base,
                         call_606321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606321, url, valid)

proc call*(call_606322: Call_DeleteBackupPlan_606310; backupPlanId: string): Recallable =
  ## deleteBackupPlan
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_606323 = newJObject()
  add(path_606323, "backupPlanId", newJString(backupPlanId))
  result = call_606322.call(path_606323, nil, nil, nil, nil)

var deleteBackupPlan* = Call_DeleteBackupPlan_606310(name: "deleteBackupPlan",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_DeleteBackupPlan_606311,
    base: "/", url: url_DeleteBackupPlan_606312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupSelection_606324 = ref object of OpenApiRestCall_605589
proc url_GetBackupSelection_606326(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupSelection_606325(path: JsonNode; query: JsonNode;
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
  var valid_606327 = path.getOrDefault("backupPlanId")
  valid_606327 = validateParameter(valid_606327, JString, required = true,
                                 default = nil)
  if valid_606327 != nil:
    section.add "backupPlanId", valid_606327
  var valid_606328 = path.getOrDefault("selectionId")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "selectionId", valid_606328
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
  var valid_606329 = header.getOrDefault("X-Amz-Signature")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Signature", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Content-Sha256", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Date")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Date", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Credential")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Credential", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Security-Token")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Security-Token", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Algorithm")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Algorithm", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-SignedHeaders", valid_606335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606336: Call_GetBackupSelection_606324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  let valid = call_606336.validator(path, query, header, formData, body)
  let scheme = call_606336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606336.url(scheme.get, call_606336.host, call_606336.base,
                         call_606336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606336, url, valid)

proc call*(call_606337: Call_GetBackupSelection_606324; backupPlanId: string;
          selectionId: string): Recallable =
  ## getBackupSelection
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_606338 = newJObject()
  add(path_606338, "backupPlanId", newJString(backupPlanId))
  add(path_606338, "selectionId", newJString(selectionId))
  result = call_606337.call(path_606338, nil, nil, nil, nil)

var getBackupSelection* = Call_GetBackupSelection_606324(
    name: "getBackupSelection", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_GetBackupSelection_606325, base: "/",
    url: url_GetBackupSelection_606326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupSelection_606339 = ref object of OpenApiRestCall_605589
proc url_DeleteBackupSelection_606341(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupSelection_606340(path: JsonNode; query: JsonNode;
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
  var valid_606342 = path.getOrDefault("backupPlanId")
  valid_606342 = validateParameter(valid_606342, JString, required = true,
                                 default = nil)
  if valid_606342 != nil:
    section.add "backupPlanId", valid_606342
  var valid_606343 = path.getOrDefault("selectionId")
  valid_606343 = validateParameter(valid_606343, JString, required = true,
                                 default = nil)
  if valid_606343 != nil:
    section.add "selectionId", valid_606343
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
  var valid_606344 = header.getOrDefault("X-Amz-Signature")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Signature", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Content-Sha256", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Date")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Date", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Credential")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Credential", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Security-Token")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Security-Token", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Algorithm")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Algorithm", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-SignedHeaders", valid_606350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606351: Call_DeleteBackupSelection_606339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  let valid = call_606351.validator(path, query, header, formData, body)
  let scheme = call_606351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606351.url(scheme.get, call_606351.host, call_606351.base,
                         call_606351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606351, url, valid)

proc call*(call_606352: Call_DeleteBackupSelection_606339; backupPlanId: string;
          selectionId: string): Recallable =
  ## deleteBackupSelection
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_606353 = newJObject()
  add(path_606353, "backupPlanId", newJString(backupPlanId))
  add(path_606353, "selectionId", newJString(selectionId))
  result = call_606352.call(path_606353, nil, nil, nil, nil)

var deleteBackupSelection* = Call_DeleteBackupSelection_606339(
    name: "deleteBackupSelection", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_DeleteBackupSelection_606340, base: "/",
    url: url_DeleteBackupSelection_606341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultAccessPolicy_606368 = ref object of OpenApiRestCall_605589
proc url_PutBackupVaultAccessPolicy_606370(protocol: Scheme; host: string;
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

proc validate_PutBackupVaultAccessPolicy_606369(path: JsonNode; query: JsonNode;
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
  var valid_606371 = path.getOrDefault("backupVaultName")
  valid_606371 = validateParameter(valid_606371, JString, required = true,
                                 default = nil)
  if valid_606371 != nil:
    section.add "backupVaultName", valid_606371
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
  var valid_606372 = header.getOrDefault("X-Amz-Signature")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Signature", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Content-Sha256", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Date")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Date", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Credential")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Credential", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Security-Token")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Security-Token", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Algorithm")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Algorithm", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-SignedHeaders", valid_606378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606380: Call_PutBackupVaultAccessPolicy_606368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  let valid = call_606380.validator(path, query, header, formData, body)
  let scheme = call_606380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606380.url(scheme.get, call_606380.host, call_606380.base,
                         call_606380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606380, url, valid)

proc call*(call_606381: Call_PutBackupVaultAccessPolicy_606368;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultAccessPolicy
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_606382 = newJObject()
  var body_606383 = newJObject()
  add(path_606382, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_606383 = body
  result = call_606381.call(path_606382, nil, nil, nil, body_606383)

var putBackupVaultAccessPolicy* = Call_PutBackupVaultAccessPolicy_606368(
    name: "putBackupVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_PutBackupVaultAccessPolicy_606369, base: "/",
    url: url_PutBackupVaultAccessPolicy_606370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultAccessPolicy_606354 = ref object of OpenApiRestCall_605589
proc url_GetBackupVaultAccessPolicy_606356(protocol: Scheme; host: string;
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

proc validate_GetBackupVaultAccessPolicy_606355(path: JsonNode; query: JsonNode;
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
  var valid_606357 = path.getOrDefault("backupVaultName")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = nil)
  if valid_606357 != nil:
    section.add "backupVaultName", valid_606357
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
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606365: Call_GetBackupVaultAccessPolicy_606354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  let valid = call_606365.validator(path, query, header, formData, body)
  let scheme = call_606365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606365.url(scheme.get, call_606365.host, call_606365.base,
                         call_606365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606365, url, valid)

proc call*(call_606366: Call_GetBackupVaultAccessPolicy_606354;
          backupVaultName: string): Recallable =
  ## getBackupVaultAccessPolicy
  ## Returns the access policy document that is associated with the named backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_606367 = newJObject()
  add(path_606367, "backupVaultName", newJString(backupVaultName))
  result = call_606366.call(path_606367, nil, nil, nil, nil)

var getBackupVaultAccessPolicy* = Call_GetBackupVaultAccessPolicy_606354(
    name: "getBackupVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_GetBackupVaultAccessPolicy_606355, base: "/",
    url: url_GetBackupVaultAccessPolicy_606356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultAccessPolicy_606384 = ref object of OpenApiRestCall_605589
proc url_DeleteBackupVaultAccessPolicy_606386(protocol: Scheme; host: string;
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

proc validate_DeleteBackupVaultAccessPolicy_606385(path: JsonNode; query: JsonNode;
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
  var valid_606387 = path.getOrDefault("backupVaultName")
  valid_606387 = validateParameter(valid_606387, JString, required = true,
                                 default = nil)
  if valid_606387 != nil:
    section.add "backupVaultName", valid_606387
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
  var valid_606388 = header.getOrDefault("X-Amz-Signature")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Signature", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Content-Sha256", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Date")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Date", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Credential")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Credential", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Security-Token")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Security-Token", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Algorithm")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Algorithm", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-SignedHeaders", valid_606394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606395: Call_DeleteBackupVaultAccessPolicy_606384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  let valid = call_606395.validator(path, query, header, formData, body)
  let scheme = call_606395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606395.url(scheme.get, call_606395.host, call_606395.base,
                         call_606395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606395, url, valid)

proc call*(call_606396: Call_DeleteBackupVaultAccessPolicy_606384;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultAccessPolicy
  ## Deletes the policy document that manages permissions on a backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_606397 = newJObject()
  add(path_606397, "backupVaultName", newJString(backupVaultName))
  result = call_606396.call(path_606397, nil, nil, nil, nil)

var deleteBackupVaultAccessPolicy* = Call_DeleteBackupVaultAccessPolicy_606384(
    name: "deleteBackupVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_DeleteBackupVaultAccessPolicy_606385, base: "/",
    url: url_DeleteBackupVaultAccessPolicy_606386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultNotifications_606412 = ref object of OpenApiRestCall_605589
proc url_PutBackupVaultNotifications_606414(protocol: Scheme; host: string;
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

proc validate_PutBackupVaultNotifications_606413(path: JsonNode; query: JsonNode;
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
  var valid_606415 = path.getOrDefault("backupVaultName")
  valid_606415 = validateParameter(valid_606415, JString, required = true,
                                 default = nil)
  if valid_606415 != nil:
    section.add "backupVaultName", valid_606415
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
  var valid_606416 = header.getOrDefault("X-Amz-Signature")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Signature", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Content-Sha256", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Date")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Date", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Credential")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Credential", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Security-Token")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Security-Token", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Algorithm")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Algorithm", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-SignedHeaders", valid_606422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606424: Call_PutBackupVaultNotifications_606412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  let valid = call_606424.validator(path, query, header, formData, body)
  let scheme = call_606424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606424.url(scheme.get, call_606424.host, call_606424.base,
                         call_606424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606424, url, valid)

proc call*(call_606425: Call_PutBackupVaultNotifications_606412;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultNotifications
  ## Turns on notifications on a backup vault for the specified topic and events.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_606426 = newJObject()
  var body_606427 = newJObject()
  add(path_606426, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_606427 = body
  result = call_606425.call(path_606426, nil, nil, nil, body_606427)

var putBackupVaultNotifications* = Call_PutBackupVaultNotifications_606412(
    name: "putBackupVaultNotifications", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_PutBackupVaultNotifications_606413, base: "/",
    url: url_PutBackupVaultNotifications_606414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultNotifications_606398 = ref object of OpenApiRestCall_605589
proc url_GetBackupVaultNotifications_606400(protocol: Scheme; host: string;
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

proc validate_GetBackupVaultNotifications_606399(path: JsonNode; query: JsonNode;
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
  var valid_606401 = path.getOrDefault("backupVaultName")
  valid_606401 = validateParameter(valid_606401, JString, required = true,
                                 default = nil)
  if valid_606401 != nil:
    section.add "backupVaultName", valid_606401
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
  var valid_606402 = header.getOrDefault("X-Amz-Signature")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Signature", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Content-Sha256", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Date")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Date", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Credential")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Credential", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Security-Token")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Security-Token", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Algorithm")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Algorithm", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-SignedHeaders", valid_606408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606409: Call_GetBackupVaultNotifications_606398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns event notifications for the specified backup vault.
  ## 
  let valid = call_606409.validator(path, query, header, formData, body)
  let scheme = call_606409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606409.url(scheme.get, call_606409.host, call_606409.base,
                         call_606409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606409, url, valid)

proc call*(call_606410: Call_GetBackupVaultNotifications_606398;
          backupVaultName: string): Recallable =
  ## getBackupVaultNotifications
  ## Returns event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_606411 = newJObject()
  add(path_606411, "backupVaultName", newJString(backupVaultName))
  result = call_606410.call(path_606411, nil, nil, nil, nil)

var getBackupVaultNotifications* = Call_GetBackupVaultNotifications_606398(
    name: "getBackupVaultNotifications", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_GetBackupVaultNotifications_606399, base: "/",
    url: url_GetBackupVaultNotifications_606400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultNotifications_606428 = ref object of OpenApiRestCall_605589
proc url_DeleteBackupVaultNotifications_606430(protocol: Scheme; host: string;
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

proc validate_DeleteBackupVaultNotifications_606429(path: JsonNode;
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
  var valid_606431 = path.getOrDefault("backupVaultName")
  valid_606431 = validateParameter(valid_606431, JString, required = true,
                                 default = nil)
  if valid_606431 != nil:
    section.add "backupVaultName", valid_606431
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
  var valid_606432 = header.getOrDefault("X-Amz-Signature")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Signature", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Content-Sha256", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Date")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Date", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Credential")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Credential", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Security-Token")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Security-Token", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Algorithm")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Algorithm", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-SignedHeaders", valid_606438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606439: Call_DeleteBackupVaultNotifications_606428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes event notifications for the specified backup vault.
  ## 
  let valid = call_606439.validator(path, query, header, formData, body)
  let scheme = call_606439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606439.url(scheme.get, call_606439.host, call_606439.base,
                         call_606439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606439, url, valid)

proc call*(call_606440: Call_DeleteBackupVaultNotifications_606428;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultNotifications
  ## Deletes event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_606441 = newJObject()
  add(path_606441, "backupVaultName", newJString(backupVaultName))
  result = call_606440.call(path_606441, nil, nil, nil, nil)

var deleteBackupVaultNotifications* = Call_DeleteBackupVaultNotifications_606428(
    name: "deleteBackupVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_DeleteBackupVaultNotifications_606429, base: "/",
    url: url_DeleteBackupVaultNotifications_606430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecoveryPointLifecycle_606457 = ref object of OpenApiRestCall_605589
proc url_UpdateRecoveryPointLifecycle_606459(protocol: Scheme; host: string;
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

proc validate_UpdateRecoveryPointLifecycle_606458(path: JsonNode; query: JsonNode;
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
  var valid_606460 = path.getOrDefault("backupVaultName")
  valid_606460 = validateParameter(valid_606460, JString, required = true,
                                 default = nil)
  if valid_606460 != nil:
    section.add "backupVaultName", valid_606460
  var valid_606461 = path.getOrDefault("recoveryPointArn")
  valid_606461 = validateParameter(valid_606461, JString, required = true,
                                 default = nil)
  if valid_606461 != nil:
    section.add "recoveryPointArn", valid_606461
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
  var valid_606462 = header.getOrDefault("X-Amz-Signature")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Signature", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Content-Sha256", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Date")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Date", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Credential")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Credential", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Security-Token")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Security-Token", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Algorithm")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Algorithm", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-SignedHeaders", valid_606468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606470: Call_UpdateRecoveryPointLifecycle_606457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  let valid = call_606470.validator(path, query, header, formData, body)
  let scheme = call_606470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606470.url(scheme.get, call_606470.host, call_606470.base,
                         call_606470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606470, url, valid)

proc call*(call_606471: Call_UpdateRecoveryPointLifecycle_606457;
          backupVaultName: string; recoveryPointArn: string; body: JsonNode): Recallable =
  ## updateRecoveryPointLifecycle
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   body: JObject (required)
  var path_606472 = newJObject()
  var body_606473 = newJObject()
  add(path_606472, "backupVaultName", newJString(backupVaultName))
  add(path_606472, "recoveryPointArn", newJString(recoveryPointArn))
  if body != nil:
    body_606473 = body
  result = call_606471.call(path_606472, nil, nil, nil, body_606473)

var updateRecoveryPointLifecycle* = Call_UpdateRecoveryPointLifecycle_606457(
    name: "updateRecoveryPointLifecycle", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_UpdateRecoveryPointLifecycle_606458, base: "/",
    url: url_UpdateRecoveryPointLifecycle_606459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecoveryPoint_606442 = ref object of OpenApiRestCall_605589
proc url_DescribeRecoveryPoint_606444(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRecoveryPoint_606443(path: JsonNode; query: JsonNode;
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
  var valid_606445 = path.getOrDefault("backupVaultName")
  valid_606445 = validateParameter(valid_606445, JString, required = true,
                                 default = nil)
  if valid_606445 != nil:
    section.add "backupVaultName", valid_606445
  var valid_606446 = path.getOrDefault("recoveryPointArn")
  valid_606446 = validateParameter(valid_606446, JString, required = true,
                                 default = nil)
  if valid_606446 != nil:
    section.add "recoveryPointArn", valid_606446
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
  var valid_606447 = header.getOrDefault("X-Amz-Signature")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Signature", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Content-Sha256", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Date")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Date", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Credential")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Credential", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Security-Token")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Security-Token", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Algorithm")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Algorithm", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-SignedHeaders", valid_606453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606454: Call_DescribeRecoveryPoint_606442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  let valid = call_606454.validator(path, query, header, formData, body)
  let scheme = call_606454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606454.url(scheme.get, call_606454.host, call_606454.base,
                         call_606454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606454, url, valid)

proc call*(call_606455: Call_DescribeRecoveryPoint_606442; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## describeRecoveryPoint
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_606456 = newJObject()
  add(path_606456, "backupVaultName", newJString(backupVaultName))
  add(path_606456, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_606455.call(path_606456, nil, nil, nil, nil)

var describeRecoveryPoint* = Call_DescribeRecoveryPoint_606442(
    name: "describeRecoveryPoint", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DescribeRecoveryPoint_606443, base: "/",
    url: url_DescribeRecoveryPoint_606444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRecoveryPoint_606474 = ref object of OpenApiRestCall_605589
proc url_DeleteRecoveryPoint_606476(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRecoveryPoint_606475(path: JsonNode; query: JsonNode;
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
  var valid_606477 = path.getOrDefault("backupVaultName")
  valid_606477 = validateParameter(valid_606477, JString, required = true,
                                 default = nil)
  if valid_606477 != nil:
    section.add "backupVaultName", valid_606477
  var valid_606478 = path.getOrDefault("recoveryPointArn")
  valid_606478 = validateParameter(valid_606478, JString, required = true,
                                 default = nil)
  if valid_606478 != nil:
    section.add "recoveryPointArn", valid_606478
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
  var valid_606479 = header.getOrDefault("X-Amz-Signature")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Signature", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Content-Sha256", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Date")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Date", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Credential")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Credential", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Security-Token")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Security-Token", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Algorithm")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Algorithm", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-SignedHeaders", valid_606485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606486: Call_DeleteRecoveryPoint_606474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  let valid = call_606486.validator(path, query, header, formData, body)
  let scheme = call_606486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606486.url(scheme.get, call_606486.host, call_606486.base,
                         call_606486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606486, url, valid)

proc call*(call_606487: Call_DeleteRecoveryPoint_606474; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## deleteRecoveryPoint
  ## Deletes the recovery point specified by a recovery point ID.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_606488 = newJObject()
  add(path_606488, "backupVaultName", newJString(backupVaultName))
  add(path_606488, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_606487.call(path_606488, nil, nil, nil, nil)

var deleteRecoveryPoint* = Call_DeleteRecoveryPoint_606474(
    name: "deleteRecoveryPoint", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DeleteRecoveryPoint_606475, base: "/",
    url: url_DeleteRecoveryPoint_606476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBackupJob_606503 = ref object of OpenApiRestCall_605589
proc url_StopBackupJob_606505(protocol: Scheme; host: string; base: string;
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

proc validate_StopBackupJob_606504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606506 = path.getOrDefault("backupJobId")
  valid_606506 = validateParameter(valid_606506, JString, required = true,
                                 default = nil)
  if valid_606506 != nil:
    section.add "backupJobId", valid_606506
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
  var valid_606507 = header.getOrDefault("X-Amz-Signature")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Signature", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Content-Sha256", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Date")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Date", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Credential")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Credential", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Security-Token")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Security-Token", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-Algorithm")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Algorithm", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-SignedHeaders", valid_606513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606514: Call_StopBackupJob_606503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  let valid = call_606514.validator(path, query, header, formData, body)
  let scheme = call_606514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606514.url(scheme.get, call_606514.host, call_606514.base,
                         call_606514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606514, url, valid)

proc call*(call_606515: Call_StopBackupJob_606503; backupJobId: string): Recallable =
  ## stopBackupJob
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_606516 = newJObject()
  add(path_606516, "backupJobId", newJString(backupJobId))
  result = call_606515.call(path_606516, nil, nil, nil, nil)

var stopBackupJob* = Call_StopBackupJob_606503(name: "stopBackupJob",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_StopBackupJob_606504,
    base: "/", url: url_StopBackupJob_606505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupJob_606489 = ref object of OpenApiRestCall_605589
proc url_DescribeBackupJob_606491(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBackupJob_606490(path: JsonNode; query: JsonNode;
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
  var valid_606492 = path.getOrDefault("backupJobId")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = nil)
  if valid_606492 != nil:
    section.add "backupJobId", valid_606492
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
  var valid_606493 = header.getOrDefault("X-Amz-Signature")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Signature", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Content-Sha256", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Date")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Date", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-Credential")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Credential", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Security-Token")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Security-Token", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Algorithm")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Algorithm", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-SignedHeaders", valid_606499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606500: Call_DescribeBackupJob_606489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  let valid = call_606500.validator(path, query, header, formData, body)
  let scheme = call_606500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606500.url(scheme.get, call_606500.host, call_606500.base,
                         call_606500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606500, url, valid)

proc call*(call_606501: Call_DescribeBackupJob_606489; backupJobId: string): Recallable =
  ## describeBackupJob
  ## Returns metadata associated with creating a backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_606502 = newJObject()
  add(path_606502, "backupJobId", newJString(backupJobId))
  result = call_606501.call(path_606502, nil, nil, nil, nil)

var describeBackupJob* = Call_DescribeBackupJob_606489(name: "describeBackupJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_DescribeBackupJob_606490,
    base: "/", url: url_DescribeBackupJob_606491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyJob_606517 = ref object of OpenApiRestCall_605589
proc url_DescribeCopyJob_606519(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCopyJob_606518(path: JsonNode; query: JsonNode;
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
  var valid_606520 = path.getOrDefault("copyJobId")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = nil)
  if valid_606520 != nil:
    section.add "copyJobId", valid_606520
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
  var valid_606521 = header.getOrDefault("X-Amz-Signature")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Signature", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Content-Sha256", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Date")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Date", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Credential")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Credential", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Security-Token")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Security-Token", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Algorithm")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Algorithm", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-SignedHeaders", valid_606527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606528: Call_DescribeCopyJob_606517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a copy of a resource.
  ## 
  let valid = call_606528.validator(path, query, header, formData, body)
  let scheme = call_606528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606528.url(scheme.get, call_606528.host, call_606528.base,
                         call_606528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606528, url, valid)

proc call*(call_606529: Call_DescribeCopyJob_606517; copyJobId: string): Recallable =
  ## describeCopyJob
  ## Returns metadata associated with creating a copy of a resource.
  ##   copyJobId: string (required)
  ##            : Uniquely identifies a request to AWS Backup to copy a resource.
  var path_606530 = newJObject()
  add(path_606530, "copyJobId", newJString(copyJobId))
  result = call_606529.call(path_606530, nil, nil, nil, nil)

var describeCopyJob* = Call_DescribeCopyJob_606517(name: "describeCopyJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/copy-jobs/{copyJobId}", validator: validate_DescribeCopyJob_606518,
    base: "/", url: url_DescribeCopyJob_606519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProtectedResource_606531 = ref object of OpenApiRestCall_605589
proc url_DescribeProtectedResource_606533(protocol: Scheme; host: string;
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

proc validate_DescribeProtectedResource_606532(path: JsonNode; query: JsonNode;
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
  var valid_606534 = path.getOrDefault("resourceArn")
  valid_606534 = validateParameter(valid_606534, JString, required = true,
                                 default = nil)
  if valid_606534 != nil:
    section.add "resourceArn", valid_606534
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
  var valid_606535 = header.getOrDefault("X-Amz-Signature")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Signature", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Content-Sha256", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Date")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Date", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Credential")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Credential", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Security-Token")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Security-Token", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Algorithm")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Algorithm", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-SignedHeaders", valid_606541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606542: Call_DescribeProtectedResource_606531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  let valid = call_606542.validator(path, query, header, formData, body)
  let scheme = call_606542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606542.url(scheme.get, call_606542.host, call_606542.base,
                         call_606542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606542, url, valid)

proc call*(call_606543: Call_DescribeProtectedResource_606531; resourceArn: string): Recallable =
  ## describeProtectedResource
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  var path_606544 = newJObject()
  add(path_606544, "resourceArn", newJString(resourceArn))
  result = call_606543.call(path_606544, nil, nil, nil, nil)

var describeProtectedResource* = Call_DescribeProtectedResource_606531(
    name: "describeProtectedResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/{resourceArn}",
    validator: validate_DescribeProtectedResource_606532, base: "/",
    url: url_DescribeProtectedResource_606533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRestoreJob_606545 = ref object of OpenApiRestCall_605589
proc url_DescribeRestoreJob_606547(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRestoreJob_606546(path: JsonNode; query: JsonNode;
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
  var valid_606548 = path.getOrDefault("restoreJobId")
  valid_606548 = validateParameter(valid_606548, JString, required = true,
                                 default = nil)
  if valid_606548 != nil:
    section.add "restoreJobId", valid_606548
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
  var valid_606549 = header.getOrDefault("X-Amz-Signature")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Signature", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Content-Sha256", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Date")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Date", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Credential")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Credential", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Security-Token")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Security-Token", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Algorithm")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Algorithm", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-SignedHeaders", valid_606555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606556: Call_DescribeRestoreJob_606545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  let valid = call_606556.validator(path, query, header, formData, body)
  let scheme = call_606556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606556.url(scheme.get, call_606556.host, call_606556.base,
                         call_606556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606556, url, valid)

proc call*(call_606557: Call_DescribeRestoreJob_606545; restoreJobId: string): Recallable =
  ## describeRestoreJob
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ##   restoreJobId: string (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  var path_606558 = newJObject()
  add(path_606558, "restoreJobId", newJString(restoreJobId))
  result = call_606557.call(path_606558, nil, nil, nil, nil)

var describeRestoreJob* = Call_DescribeRestoreJob_606545(
    name: "describeRestoreJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/restore-jobs/{restoreJobId}",
    validator: validate_DescribeRestoreJob_606546, base: "/",
    url: url_DescribeRestoreJob_606547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBackupPlanTemplate_606559 = ref object of OpenApiRestCall_605589
proc url_ExportBackupPlanTemplate_606561(protocol: Scheme; host: string;
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

proc validate_ExportBackupPlanTemplate_606560(path: JsonNode; query: JsonNode;
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
  var valid_606562 = path.getOrDefault("backupPlanId")
  valid_606562 = validateParameter(valid_606562, JString, required = true,
                                 default = nil)
  if valid_606562 != nil:
    section.add "backupPlanId", valid_606562
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
  var valid_606563 = header.getOrDefault("X-Amz-Signature")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Signature", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Content-Sha256", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Date")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Date", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Credential")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Credential", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Security-Token")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Security-Token", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Algorithm")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Algorithm", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-SignedHeaders", valid_606569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606570: Call_ExportBackupPlanTemplate_606559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  let valid = call_606570.validator(path, query, header, formData, body)
  let scheme = call_606570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606570.url(scheme.get, call_606570.host, call_606570.base,
                         call_606570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606570, url, valid)

proc call*(call_606571: Call_ExportBackupPlanTemplate_606559; backupPlanId: string): Recallable =
  ## exportBackupPlanTemplate
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_606572 = newJObject()
  add(path_606572, "backupPlanId", newJString(backupPlanId))
  result = call_606571.call(path_606572, nil, nil, nil, nil)

var exportBackupPlanTemplate* = Call_ExportBackupPlanTemplate_606559(
    name: "exportBackupPlanTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/toTemplate/",
    validator: validate_ExportBackupPlanTemplate_606560, base: "/",
    url: url_ExportBackupPlanTemplate_606561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlan_606573 = ref object of OpenApiRestCall_605589
proc url_GetBackupPlan_606575(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupPlan_606574(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606576 = path.getOrDefault("backupPlanId")
  valid_606576 = validateParameter(valid_606576, JString, required = true,
                                 default = nil)
  if valid_606576 != nil:
    section.add "backupPlanId", valid_606576
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  section = newJObject()
  var valid_606577 = query.getOrDefault("versionId")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "versionId", valid_606577
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
  var valid_606578 = header.getOrDefault("X-Amz-Signature")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Signature", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Content-Sha256", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Date")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Date", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Credential")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Credential", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Security-Token")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Security-Token", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Algorithm")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Algorithm", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-SignedHeaders", valid_606584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606585: Call_GetBackupPlan_606573; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  let valid = call_606585.validator(path, query, header, formData, body)
  let scheme = call_606585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606585.url(scheme.get, call_606585.host, call_606585.base,
                         call_606585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606585, url, valid)

proc call*(call_606586: Call_GetBackupPlan_606573; backupPlanId: string;
          versionId: string = ""): Recallable =
  ## getBackupPlan
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ##   versionId: string
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_606587 = newJObject()
  var query_606588 = newJObject()
  add(query_606588, "versionId", newJString(versionId))
  add(path_606587, "backupPlanId", newJString(backupPlanId))
  result = call_606586.call(path_606587, query_606588, nil, nil, nil)

var getBackupPlan* = Call_GetBackupPlan_606573(name: "getBackupPlan",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/", validator: validate_GetBackupPlan_606574,
    base: "/", url: url_GetBackupPlan_606575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromJSON_606589 = ref object of OpenApiRestCall_605589
proc url_GetBackupPlanFromJSON_606591(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupPlanFromJSON_606590(path: JsonNode; query: JsonNode;
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
  var valid_606592 = header.getOrDefault("X-Amz-Signature")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Signature", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Content-Sha256", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Date")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Date", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Credential")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Credential", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Security-Token")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Security-Token", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Algorithm")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Algorithm", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-SignedHeaders", valid_606598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606600: Call_GetBackupPlanFromJSON_606589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  let valid = call_606600.validator(path, query, header, formData, body)
  let scheme = call_606600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606600.url(scheme.get, call_606600.host, call_606600.base,
                         call_606600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606600, url, valid)

proc call*(call_606601: Call_GetBackupPlanFromJSON_606589; body: JsonNode): Recallable =
  ## getBackupPlanFromJSON
  ## Returns a valid JSON document specifying a backup plan or an error.
  ##   body: JObject (required)
  var body_606602 = newJObject()
  if body != nil:
    body_606602 = body
  result = call_606601.call(nil, nil, nil, nil, body_606602)

var getBackupPlanFromJSON* = Call_GetBackupPlanFromJSON_606589(
    name: "getBackupPlanFromJSON", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/template/json/toPlan",
    validator: validate_GetBackupPlanFromJSON_606590, base: "/",
    url: url_GetBackupPlanFromJSON_606591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromTemplate_606603 = ref object of OpenApiRestCall_605589
proc url_GetBackupPlanFromTemplate_606605(protocol: Scheme; host: string;
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

proc validate_GetBackupPlanFromTemplate_606604(path: JsonNode; query: JsonNode;
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
  var valid_606606 = path.getOrDefault("templateId")
  valid_606606 = validateParameter(valid_606606, JString, required = true,
                                 default = nil)
  if valid_606606 != nil:
    section.add "templateId", valid_606606
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
  var valid_606607 = header.getOrDefault("X-Amz-Signature")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Signature", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Content-Sha256", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Date")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Date", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Credential")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Credential", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Security-Token")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Security-Token", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Algorithm")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Algorithm", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-SignedHeaders", valid_606613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606614: Call_GetBackupPlanFromTemplate_606603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  let valid = call_606614.validator(path, query, header, formData, body)
  let scheme = call_606614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606614.url(scheme.get, call_606614.host, call_606614.base,
                         call_606614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606614, url, valid)

proc call*(call_606615: Call_GetBackupPlanFromTemplate_606603; templateId: string): Recallable =
  ## getBackupPlanFromTemplate
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ##   templateId: string (required)
  ##             : Uniquely identifies a stored backup plan template.
  var path_606616 = newJObject()
  add(path_606616, "templateId", newJString(templateId))
  result = call_606615.call(path_606616, nil, nil, nil, nil)

var getBackupPlanFromTemplate* = Call_GetBackupPlanFromTemplate_606603(
    name: "getBackupPlanFromTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/template/plans/{templateId}/toPlan",
    validator: validate_GetBackupPlanFromTemplate_606604, base: "/",
    url: url_GetBackupPlanFromTemplate_606605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecoveryPointRestoreMetadata_606617 = ref object of OpenApiRestCall_605589
proc url_GetRecoveryPointRestoreMetadata_606619(protocol: Scheme; host: string;
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

proc validate_GetRecoveryPointRestoreMetadata_606618(path: JsonNode;
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
  var valid_606620 = path.getOrDefault("backupVaultName")
  valid_606620 = validateParameter(valid_606620, JString, required = true,
                                 default = nil)
  if valid_606620 != nil:
    section.add "backupVaultName", valid_606620
  var valid_606621 = path.getOrDefault("recoveryPointArn")
  valid_606621 = validateParameter(valid_606621, JString, required = true,
                                 default = nil)
  if valid_606621 != nil:
    section.add "recoveryPointArn", valid_606621
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
  var valid_606622 = header.getOrDefault("X-Amz-Signature")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Signature", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Content-Sha256", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Date")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Date", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Credential")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Credential", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Security-Token")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Security-Token", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Algorithm")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Algorithm", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-SignedHeaders", valid_606628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606629: Call_GetRecoveryPointRestoreMetadata_606617;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ## 
  let valid = call_606629.validator(path, query, header, formData, body)
  let scheme = call_606629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606629.url(scheme.get, call_606629.host, call_606629.base,
                         call_606629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606629, url, valid)

proc call*(call_606630: Call_GetRecoveryPointRestoreMetadata_606617;
          backupVaultName: string; recoveryPointArn: string): Recallable =
  ## getRecoveryPointRestoreMetadata
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_606631 = newJObject()
  add(path_606631, "backupVaultName", newJString(backupVaultName))
  add(path_606631, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_606630.call(path_606631, nil, nil, nil, nil)

var getRecoveryPointRestoreMetadata* = Call_GetRecoveryPointRestoreMetadata_606617(
    name: "getRecoveryPointRestoreMetadata", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}/restore-metadata",
    validator: validate_GetRecoveryPointRestoreMetadata_606618, base: "/",
    url: url_GetRecoveryPointRestoreMetadata_606619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSupportedResourceTypes_606632 = ref object of OpenApiRestCall_605589
proc url_GetSupportedResourceTypes_606634(protocol: Scheme; host: string;
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

proc validate_GetSupportedResourceTypes_606633(path: JsonNode; query: JsonNode;
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
  var valid_606635 = header.getOrDefault("X-Amz-Signature")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Signature", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Content-Sha256", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Date")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Date", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Credential")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Credential", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Security-Token")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Security-Token", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Algorithm")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Algorithm", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-SignedHeaders", valid_606641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606642: Call_GetSupportedResourceTypes_606632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  let valid = call_606642.validator(path, query, header, formData, body)
  let scheme = call_606642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606642.url(scheme.get, call_606642.host, call_606642.base,
                         call_606642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606642, url, valid)

proc call*(call_606643: Call_GetSupportedResourceTypes_606632): Recallable =
  ## getSupportedResourceTypes
  ## Returns the AWS resource types supported by AWS Backup.
  result = call_606643.call(nil, nil, nil, nil, nil)

var getSupportedResourceTypes* = Call_GetSupportedResourceTypes_606632(
    name: "getSupportedResourceTypes", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/supported-resource-types",
    validator: validate_GetSupportedResourceTypes_606633, base: "/",
    url: url_GetSupportedResourceTypes_606634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupJobs_606644 = ref object of OpenApiRestCall_605589
proc url_ListBackupJobs_606646(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupJobs_606645(path: JsonNode; query: JsonNode;
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
  var valid_606647 = query.getOrDefault("nextToken")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "nextToken", valid_606647
  var valid_606648 = query.getOrDefault("backupVaultName")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "backupVaultName", valid_606648
  var valid_606649 = query.getOrDefault("MaxResults")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "MaxResults", valid_606649
  var valid_606663 = query.getOrDefault("state")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_606663 != nil:
    section.add "state", valid_606663
  var valid_606664 = query.getOrDefault("NextToken")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "NextToken", valid_606664
  var valid_606665 = query.getOrDefault("createdAfter")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "createdAfter", valid_606665
  var valid_606666 = query.getOrDefault("resourceType")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "resourceType", valid_606666
  var valid_606667 = query.getOrDefault("createdBefore")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "createdBefore", valid_606667
  var valid_606668 = query.getOrDefault("resourceArn")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "resourceArn", valid_606668
  var valid_606669 = query.getOrDefault("maxResults")
  valid_606669 = validateParameter(valid_606669, JInt, required = false, default = nil)
  if valid_606669 != nil:
    section.add "maxResults", valid_606669
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
  var valid_606670 = header.getOrDefault("X-Amz-Signature")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Signature", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Content-Sha256", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Date")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Date", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Credential")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Credential", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Security-Token")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Security-Token", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Algorithm")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Algorithm", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-SignedHeaders", valid_606676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606677: Call_ListBackupJobs_606644; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your backup jobs.
  ## 
  let valid = call_606677.validator(path, query, header, formData, body)
  let scheme = call_606677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606677.url(scheme.get, call_606677.host, call_606677.base,
                         call_606677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606677, url, valid)

proc call*(call_606678: Call_ListBackupJobs_606644; nextToken: string = "";
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
  var query_606679 = newJObject()
  add(query_606679, "nextToken", newJString(nextToken))
  add(query_606679, "backupVaultName", newJString(backupVaultName))
  add(query_606679, "MaxResults", newJString(MaxResults))
  add(query_606679, "state", newJString(state))
  add(query_606679, "NextToken", newJString(NextToken))
  add(query_606679, "createdAfter", newJString(createdAfter))
  add(query_606679, "resourceType", newJString(resourceType))
  add(query_606679, "createdBefore", newJString(createdBefore))
  add(query_606679, "resourceArn", newJString(resourceArn))
  add(query_606679, "maxResults", newJInt(maxResults))
  result = call_606678.call(nil, query_606679, nil, nil, nil)

var listBackupJobs* = Call_ListBackupJobs_606644(name: "listBackupJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup-jobs/",
    validator: validate_ListBackupJobs_606645, base: "/", url: url_ListBackupJobs_606646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanTemplates_606680 = ref object of OpenApiRestCall_605589
proc url_ListBackupPlanTemplates_606682(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlanTemplates_606681(path: JsonNode; query: JsonNode;
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
  var valid_606683 = query.getOrDefault("nextToken")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "nextToken", valid_606683
  var valid_606684 = query.getOrDefault("MaxResults")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "MaxResults", valid_606684
  var valid_606685 = query.getOrDefault("NextToken")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "NextToken", valid_606685
  var valid_606686 = query.getOrDefault("maxResults")
  valid_606686 = validateParameter(valid_606686, JInt, required = false, default = nil)
  if valid_606686 != nil:
    section.add "maxResults", valid_606686
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
  var valid_606687 = header.getOrDefault("X-Amz-Signature")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Signature", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Content-Sha256", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Date")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Date", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Credential")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Credential", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Security-Token")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Security-Token", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Algorithm")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Algorithm", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-SignedHeaders", valid_606693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606694: Call_ListBackupPlanTemplates_606680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  let valid = call_606694.validator(path, query, header, formData, body)
  let scheme = call_606694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606694.url(scheme.get, call_606694.host, call_606694.base,
                         call_606694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606694, url, valid)

proc call*(call_606695: Call_ListBackupPlanTemplates_606680;
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
  var query_606696 = newJObject()
  add(query_606696, "nextToken", newJString(nextToken))
  add(query_606696, "MaxResults", newJString(MaxResults))
  add(query_606696, "NextToken", newJString(NextToken))
  add(query_606696, "maxResults", newJInt(maxResults))
  result = call_606695.call(nil, query_606696, nil, nil, nil)

var listBackupPlanTemplates* = Call_ListBackupPlanTemplates_606680(
    name: "listBackupPlanTemplates", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/template/plans",
    validator: validate_ListBackupPlanTemplates_606681, base: "/",
    url: url_ListBackupPlanTemplates_606682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanVersions_606697 = ref object of OpenApiRestCall_605589
proc url_ListBackupPlanVersions_606699(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlanVersions_606698(path: JsonNode; query: JsonNode;
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
  var valid_606700 = path.getOrDefault("backupPlanId")
  valid_606700 = validateParameter(valid_606700, JString, required = true,
                                 default = nil)
  if valid_606700 != nil:
    section.add "backupPlanId", valid_606700
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
  var valid_606701 = query.getOrDefault("nextToken")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "nextToken", valid_606701
  var valid_606702 = query.getOrDefault("MaxResults")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "MaxResults", valid_606702
  var valid_606703 = query.getOrDefault("NextToken")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "NextToken", valid_606703
  var valid_606704 = query.getOrDefault("maxResults")
  valid_606704 = validateParameter(valid_606704, JInt, required = false, default = nil)
  if valid_606704 != nil:
    section.add "maxResults", valid_606704
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
  var valid_606705 = header.getOrDefault("X-Amz-Signature")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Signature", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Content-Sha256", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Date")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Date", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Credential")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Credential", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Security-Token")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Security-Token", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Algorithm")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Algorithm", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-SignedHeaders", valid_606711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606712: Call_ListBackupPlanVersions_606697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  let valid = call_606712.validator(path, query, header, formData, body)
  let scheme = call_606712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606712.url(scheme.get, call_606712.host, call_606712.base,
                         call_606712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606712, url, valid)

proc call*(call_606713: Call_ListBackupPlanVersions_606697; backupPlanId: string;
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
  var path_606714 = newJObject()
  var query_606715 = newJObject()
  add(query_606715, "nextToken", newJString(nextToken))
  add(query_606715, "MaxResults", newJString(MaxResults))
  add(query_606715, "NextToken", newJString(NextToken))
  add(path_606714, "backupPlanId", newJString(backupPlanId))
  add(query_606715, "maxResults", newJInt(maxResults))
  result = call_606713.call(path_606714, query_606715, nil, nil, nil)

var listBackupPlanVersions* = Call_ListBackupPlanVersions_606697(
    name: "listBackupPlanVersions", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}/versions/",
    validator: validate_ListBackupPlanVersions_606698, base: "/",
    url: url_ListBackupPlanVersions_606699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupVaults_606716 = ref object of OpenApiRestCall_605589
proc url_ListBackupVaults_606718(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupVaults_606717(path: JsonNode; query: JsonNode;
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
  var valid_606719 = query.getOrDefault("nextToken")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "nextToken", valid_606719
  var valid_606720 = query.getOrDefault("MaxResults")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "MaxResults", valid_606720
  var valid_606721 = query.getOrDefault("NextToken")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "NextToken", valid_606721
  var valid_606722 = query.getOrDefault("maxResults")
  valid_606722 = validateParameter(valid_606722, JInt, required = false, default = nil)
  if valid_606722 != nil:
    section.add "maxResults", valid_606722
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
  var valid_606723 = header.getOrDefault("X-Amz-Signature")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Signature", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Content-Sha256", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Date")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Date", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Credential")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Credential", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Security-Token")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Security-Token", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Algorithm")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Algorithm", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-SignedHeaders", valid_606729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606730: Call_ListBackupVaults_606716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  let valid = call_606730.validator(path, query, header, formData, body)
  let scheme = call_606730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606730.url(scheme.get, call_606730.host, call_606730.base,
                         call_606730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606730, url, valid)

proc call*(call_606731: Call_ListBackupVaults_606716; nextToken: string = "";
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
  var query_606732 = newJObject()
  add(query_606732, "nextToken", newJString(nextToken))
  add(query_606732, "MaxResults", newJString(MaxResults))
  add(query_606732, "NextToken", newJString(NextToken))
  add(query_606732, "maxResults", newJInt(maxResults))
  result = call_606731.call(nil, query_606732, nil, nil, nil)

var listBackupVaults* = Call_ListBackupVaults_606716(name: "listBackupVaults",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-vaults/", validator: validate_ListBackupVaults_606717,
    base: "/", url: url_ListBackupVaults_606718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCopyJobs_606733 = ref object of OpenApiRestCall_605589
proc url_ListCopyJobs_606735(protocol: Scheme; host: string; base: string;
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

proc validate_ListCopyJobs_606734(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606736 = query.getOrDefault("nextToken")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "nextToken", valid_606736
  var valid_606737 = query.getOrDefault("MaxResults")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "MaxResults", valid_606737
  var valid_606738 = query.getOrDefault("state")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_606738 != nil:
    section.add "state", valid_606738
  var valid_606739 = query.getOrDefault("NextToken")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "NextToken", valid_606739
  var valid_606740 = query.getOrDefault("createdAfter")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "createdAfter", valid_606740
  var valid_606741 = query.getOrDefault("resourceType")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "resourceType", valid_606741
  var valid_606742 = query.getOrDefault("destinationVaultArn")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "destinationVaultArn", valid_606742
  var valid_606743 = query.getOrDefault("createdBefore")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "createdBefore", valid_606743
  var valid_606744 = query.getOrDefault("resourceArn")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "resourceArn", valid_606744
  var valid_606745 = query.getOrDefault("maxResults")
  valid_606745 = validateParameter(valid_606745, JInt, required = false, default = nil)
  if valid_606745 != nil:
    section.add "maxResults", valid_606745
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
  var valid_606746 = header.getOrDefault("X-Amz-Signature")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Signature", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Content-Sha256", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Date")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Date", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Credential")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Credential", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Security-Token")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Security-Token", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Algorithm")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Algorithm", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-SignedHeaders", valid_606752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606753: Call_ListCopyJobs_606733; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your copy jobs.
  ## 
  let valid = call_606753.validator(path, query, header, formData, body)
  let scheme = call_606753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606753.url(scheme.get, call_606753.host, call_606753.base,
                         call_606753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606753, url, valid)

proc call*(call_606754: Call_ListCopyJobs_606733; nextToken: string = "";
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
  var query_606755 = newJObject()
  add(query_606755, "nextToken", newJString(nextToken))
  add(query_606755, "MaxResults", newJString(MaxResults))
  add(query_606755, "state", newJString(state))
  add(query_606755, "NextToken", newJString(NextToken))
  add(query_606755, "createdAfter", newJString(createdAfter))
  add(query_606755, "resourceType", newJString(resourceType))
  add(query_606755, "destinationVaultArn", newJString(destinationVaultArn))
  add(query_606755, "createdBefore", newJString(createdBefore))
  add(query_606755, "resourceArn", newJString(resourceArn))
  add(query_606755, "maxResults", newJInt(maxResults))
  result = call_606754.call(nil, query_606755, nil, nil, nil)

var listCopyJobs* = Call_ListCopyJobs_606733(name: "listCopyJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/copy-jobs/",
    validator: validate_ListCopyJobs_606734, base: "/", url: url_ListCopyJobs_606735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProtectedResources_606756 = ref object of OpenApiRestCall_605589
proc url_ListProtectedResources_606758(protocol: Scheme; host: string; base: string;
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

proc validate_ListProtectedResources_606757(path: JsonNode; query: JsonNode;
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
  var valid_606759 = query.getOrDefault("nextToken")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "nextToken", valid_606759
  var valid_606760 = query.getOrDefault("MaxResults")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "MaxResults", valid_606760
  var valid_606761 = query.getOrDefault("NextToken")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "NextToken", valid_606761
  var valid_606762 = query.getOrDefault("maxResults")
  valid_606762 = validateParameter(valid_606762, JInt, required = false, default = nil)
  if valid_606762 != nil:
    section.add "maxResults", valid_606762
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
  var valid_606763 = header.getOrDefault("X-Amz-Signature")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Signature", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Content-Sha256", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Date")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Date", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Credential")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Credential", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Security-Token")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Security-Token", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Algorithm")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Algorithm", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-SignedHeaders", valid_606769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606770: Call_ListProtectedResources_606756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  let valid = call_606770.validator(path, query, header, formData, body)
  let scheme = call_606770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606770.url(scheme.get, call_606770.host, call_606770.base,
                         call_606770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606770, url, valid)

proc call*(call_606771: Call_ListProtectedResources_606756; nextToken: string = "";
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
  var query_606772 = newJObject()
  add(query_606772, "nextToken", newJString(nextToken))
  add(query_606772, "MaxResults", newJString(MaxResults))
  add(query_606772, "NextToken", newJString(NextToken))
  add(query_606772, "maxResults", newJInt(maxResults))
  result = call_606771.call(nil, query_606772, nil, nil, nil)

var listProtectedResources* = Call_ListProtectedResources_606756(
    name: "listProtectedResources", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/",
    validator: validate_ListProtectedResources_606757, base: "/",
    url: url_ListProtectedResources_606758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByBackupVault_606773 = ref object of OpenApiRestCall_605589
proc url_ListRecoveryPointsByBackupVault_606775(protocol: Scheme; host: string;
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

proc validate_ListRecoveryPointsByBackupVault_606774(path: JsonNode;
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
  var valid_606776 = path.getOrDefault("backupVaultName")
  valid_606776 = validateParameter(valid_606776, JString, required = true,
                                 default = nil)
  if valid_606776 != nil:
    section.add "backupVaultName", valid_606776
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
  var valid_606777 = query.getOrDefault("nextToken")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "nextToken", valid_606777
  var valid_606778 = query.getOrDefault("MaxResults")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "MaxResults", valid_606778
  var valid_606779 = query.getOrDefault("backupPlanId")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "backupPlanId", valid_606779
  var valid_606780 = query.getOrDefault("NextToken")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "NextToken", valid_606780
  var valid_606781 = query.getOrDefault("createdAfter")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "createdAfter", valid_606781
  var valid_606782 = query.getOrDefault("resourceType")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "resourceType", valid_606782
  var valid_606783 = query.getOrDefault("createdBefore")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "createdBefore", valid_606783
  var valid_606784 = query.getOrDefault("resourceArn")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "resourceArn", valid_606784
  var valid_606785 = query.getOrDefault("maxResults")
  valid_606785 = validateParameter(valid_606785, JInt, required = false, default = nil)
  if valid_606785 != nil:
    section.add "maxResults", valid_606785
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
  var valid_606786 = header.getOrDefault("X-Amz-Signature")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Signature", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Content-Sha256", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Date")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Date", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Credential")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Credential", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Security-Token")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Security-Token", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Algorithm")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Algorithm", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-SignedHeaders", valid_606792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606793: Call_ListRecoveryPointsByBackupVault_606773;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  let valid = call_606793.validator(path, query, header, formData, body)
  let scheme = call_606793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606793.url(scheme.get, call_606793.host, call_606793.base,
                         call_606793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606793, url, valid)

proc call*(call_606794: Call_ListRecoveryPointsByBackupVault_606773;
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
  var path_606795 = newJObject()
  var query_606796 = newJObject()
  add(query_606796, "nextToken", newJString(nextToken))
  add(query_606796, "MaxResults", newJString(MaxResults))
  add(path_606795, "backupVaultName", newJString(backupVaultName))
  add(query_606796, "backupPlanId", newJString(backupPlanId))
  add(query_606796, "NextToken", newJString(NextToken))
  add(query_606796, "createdAfter", newJString(createdAfter))
  add(query_606796, "resourceType", newJString(resourceType))
  add(query_606796, "createdBefore", newJString(createdBefore))
  add(query_606796, "resourceArn", newJString(resourceArn))
  add(query_606796, "maxResults", newJInt(maxResults))
  result = call_606794.call(path_606795, query_606796, nil, nil, nil)

var listRecoveryPointsByBackupVault* = Call_ListRecoveryPointsByBackupVault_606773(
    name: "listRecoveryPointsByBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/recovery-points/",
    validator: validate_ListRecoveryPointsByBackupVault_606774, base: "/",
    url: url_ListRecoveryPointsByBackupVault_606775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByResource_606797 = ref object of OpenApiRestCall_605589
proc url_ListRecoveryPointsByResource_606799(protocol: Scheme; host: string;
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

proc validate_ListRecoveryPointsByResource_606798(path: JsonNode; query: JsonNode;
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
  var valid_606800 = path.getOrDefault("resourceArn")
  valid_606800 = validateParameter(valid_606800, JString, required = true,
                                 default = nil)
  if valid_606800 != nil:
    section.add "resourceArn", valid_606800
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
  var valid_606801 = query.getOrDefault("nextToken")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "nextToken", valid_606801
  var valid_606802 = query.getOrDefault("MaxResults")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "MaxResults", valid_606802
  var valid_606803 = query.getOrDefault("NextToken")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "NextToken", valid_606803
  var valid_606804 = query.getOrDefault("maxResults")
  valid_606804 = validateParameter(valid_606804, JInt, required = false, default = nil)
  if valid_606804 != nil:
    section.add "maxResults", valid_606804
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
  var valid_606805 = header.getOrDefault("X-Amz-Signature")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Signature", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-Content-Sha256", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Date")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Date", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Credential")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Credential", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Security-Token")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Security-Token", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Algorithm")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Algorithm", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-SignedHeaders", valid_606811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606812: Call_ListRecoveryPointsByResource_606797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  let valid = call_606812.validator(path, query, header, formData, body)
  let scheme = call_606812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606812.url(scheme.get, call_606812.host, call_606812.base,
                         call_606812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606812, url, valid)

proc call*(call_606813: Call_ListRecoveryPointsByResource_606797;
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
  var path_606814 = newJObject()
  var query_606815 = newJObject()
  add(query_606815, "nextToken", newJString(nextToken))
  add(query_606815, "MaxResults", newJString(MaxResults))
  add(path_606814, "resourceArn", newJString(resourceArn))
  add(query_606815, "NextToken", newJString(NextToken))
  add(query_606815, "maxResults", newJInt(maxResults))
  result = call_606813.call(path_606814, query_606815, nil, nil, nil)

var listRecoveryPointsByResource* = Call_ListRecoveryPointsByResource_606797(
    name: "listRecoveryPointsByResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/resources/{resourceArn}/recovery-points/",
    validator: validate_ListRecoveryPointsByResource_606798, base: "/",
    url: url_ListRecoveryPointsByResource_606799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRestoreJobs_606816 = ref object of OpenApiRestCall_605589
proc url_ListRestoreJobs_606818(protocol: Scheme; host: string; base: string;
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

proc validate_ListRestoreJobs_606817(path: JsonNode; query: JsonNode;
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
  var valid_606819 = query.getOrDefault("nextToken")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "nextToken", valid_606819
  var valid_606820 = query.getOrDefault("MaxResults")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "MaxResults", valid_606820
  var valid_606821 = query.getOrDefault("NextToken")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "NextToken", valid_606821
  var valid_606822 = query.getOrDefault("maxResults")
  valid_606822 = validateParameter(valid_606822, JInt, required = false, default = nil)
  if valid_606822 != nil:
    section.add "maxResults", valid_606822
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
  var valid_606823 = header.getOrDefault("X-Amz-Signature")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Signature", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Content-Sha256", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Date")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Date", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Credential")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Credential", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Security-Token")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Security-Token", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Algorithm")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Algorithm", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-SignedHeaders", valid_606829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606830: Call_ListRestoreJobs_606816; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  let valid = call_606830.validator(path, query, header, formData, body)
  let scheme = call_606830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606830.url(scheme.get, call_606830.host, call_606830.base,
                         call_606830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606830, url, valid)

proc call*(call_606831: Call_ListRestoreJobs_606816; nextToken: string = "";
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
  var query_606832 = newJObject()
  add(query_606832, "nextToken", newJString(nextToken))
  add(query_606832, "MaxResults", newJString(MaxResults))
  add(query_606832, "NextToken", newJString(NextToken))
  add(query_606832, "maxResults", newJInt(maxResults))
  result = call_606831.call(nil, query_606832, nil, nil, nil)

var listRestoreJobs* = Call_ListRestoreJobs_606816(name: "listRestoreJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/restore-jobs/",
    validator: validate_ListRestoreJobs_606817, base: "/", url: url_ListRestoreJobs_606818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_606833 = ref object of OpenApiRestCall_605589
proc url_ListTags_606835(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_606834(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606836 = path.getOrDefault("resourceArn")
  valid_606836 = validateParameter(valid_606836, JString, required = true,
                                 default = nil)
  if valid_606836 != nil:
    section.add "resourceArn", valid_606836
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
  var valid_606837 = query.getOrDefault("nextToken")
  valid_606837 = validateParameter(valid_606837, JString, required = false,
                                 default = nil)
  if valid_606837 != nil:
    section.add "nextToken", valid_606837
  var valid_606838 = query.getOrDefault("MaxResults")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "MaxResults", valid_606838
  var valid_606839 = query.getOrDefault("NextToken")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "NextToken", valid_606839
  var valid_606840 = query.getOrDefault("maxResults")
  valid_606840 = validateParameter(valid_606840, JInt, required = false, default = nil)
  if valid_606840 != nil:
    section.add "maxResults", valid_606840
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
  var valid_606841 = header.getOrDefault("X-Amz-Signature")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Signature", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Content-Sha256", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Date")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Date", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Credential")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Credential", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Security-Token")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Security-Token", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Algorithm")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Algorithm", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-SignedHeaders", valid_606847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606848: Call_ListTags_606833; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  let valid = call_606848.validator(path, query, header, formData, body)
  let scheme = call_606848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606848.url(scheme.get, call_606848.host, call_606848.base,
                         call_606848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606848, url, valid)

proc call*(call_606849: Call_ListTags_606833; resourceArn: string;
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
  var path_606850 = newJObject()
  var query_606851 = newJObject()
  add(query_606851, "nextToken", newJString(nextToken))
  add(query_606851, "MaxResults", newJString(MaxResults))
  add(path_606850, "resourceArn", newJString(resourceArn))
  add(query_606851, "NextToken", newJString(NextToken))
  add(query_606851, "maxResults", newJInt(maxResults))
  result = call_606849.call(path_606850, query_606851, nil, nil, nil)

var listTags* = Call_ListTags_606833(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "backup.amazonaws.com",
                                  route: "/tags/{resourceArn}/",
                                  validator: validate_ListTags_606834, base: "/",
                                  url: url_ListTags_606835,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBackupJob_606852 = ref object of OpenApiRestCall_605589
proc url_StartBackupJob_606854(protocol: Scheme; host: string; base: string;
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

proc validate_StartBackupJob_606853(path: JsonNode; query: JsonNode;
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
  var valid_606855 = header.getOrDefault("X-Amz-Signature")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Signature", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Content-Sha256", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Date")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Date", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Credential")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Credential", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Security-Token")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Security-Token", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Algorithm")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Algorithm", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-SignedHeaders", valid_606861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606863: Call_StartBackupJob_606852; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  let valid = call_606863.validator(path, query, header, formData, body)
  let scheme = call_606863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606863.url(scheme.get, call_606863.host, call_606863.base,
                         call_606863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606863, url, valid)

proc call*(call_606864: Call_StartBackupJob_606852; body: JsonNode): Recallable =
  ## startBackupJob
  ## Starts a job to create a one-time backup of the specified resource.
  ##   body: JObject (required)
  var body_606865 = newJObject()
  if body != nil:
    body_606865 = body
  result = call_606864.call(nil, nil, nil, nil, body_606865)

var startBackupJob* = Call_StartBackupJob_606852(name: "startBackupJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup-jobs",
    validator: validate_StartBackupJob_606853, base: "/", url: url_StartBackupJob_606854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCopyJob_606866 = ref object of OpenApiRestCall_605589
proc url_StartCopyJob_606868(protocol: Scheme; host: string; base: string;
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

proc validate_StartCopyJob_606867(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606869 = header.getOrDefault("X-Amz-Signature")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Signature", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Content-Sha256", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Date")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Date", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Credential")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Credential", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Security-Token")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Security-Token", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Algorithm")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Algorithm", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-SignedHeaders", valid_606875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606877: Call_StartCopyJob_606866; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time copy of the specified resource.
  ## 
  let valid = call_606877.validator(path, query, header, formData, body)
  let scheme = call_606877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606877.url(scheme.get, call_606877.host, call_606877.base,
                         call_606877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606877, url, valid)

proc call*(call_606878: Call_StartCopyJob_606866; body: JsonNode): Recallable =
  ## startCopyJob
  ## Starts a job to create a one-time copy of the specified resource.
  ##   body: JObject (required)
  var body_606879 = newJObject()
  if body != nil:
    body_606879 = body
  result = call_606878.call(nil, nil, nil, nil, body_606879)

var startCopyJob* = Call_StartCopyJob_606866(name: "startCopyJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/copy-jobs",
    validator: validate_StartCopyJob_606867, base: "/", url: url_StartCopyJob_606868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRestoreJob_606880 = ref object of OpenApiRestCall_605589
proc url_StartRestoreJob_606882(protocol: Scheme; host: string; base: string;
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

proc validate_StartRestoreJob_606881(path: JsonNode; query: JsonNode;
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
  var valid_606883 = header.getOrDefault("X-Amz-Signature")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Signature", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Content-Sha256", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Date")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Date", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Credential")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Credential", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Security-Token")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Security-Token", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-Algorithm")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Algorithm", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-SignedHeaders", valid_606889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606891: Call_StartRestoreJob_606880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  let valid = call_606891.validator(path, query, header, formData, body)
  let scheme = call_606891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606891.url(scheme.get, call_606891.host, call_606891.base,
                         call_606891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606891, url, valid)

proc call*(call_606892: Call_StartRestoreJob_606880; body: JsonNode): Recallable =
  ## startRestoreJob
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ##   body: JObject (required)
  var body_606893 = newJObject()
  if body != nil:
    body_606893 = body
  result = call_606892.call(nil, nil, nil, nil, body_606893)

var startRestoreJob* = Call_StartRestoreJob_606880(name: "startRestoreJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/restore-jobs",
    validator: validate_StartRestoreJob_606881, base: "/", url: url_StartRestoreJob_606882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606894 = ref object of OpenApiRestCall_605589
proc url_TagResource_606896(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606895(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606897 = path.getOrDefault("resourceArn")
  valid_606897 = validateParameter(valid_606897, JString, required = true,
                                 default = nil)
  if valid_606897 != nil:
    section.add "resourceArn", valid_606897
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
  var valid_606898 = header.getOrDefault("X-Amz-Signature")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Signature", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Content-Sha256", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Date")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Date", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Credential")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Credential", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Security-Token")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Security-Token", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Algorithm")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Algorithm", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-SignedHeaders", valid_606904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606906: Call_TagResource_606894; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  let valid = call_606906.validator(path, query, header, formData, body)
  let scheme = call_606906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606906.url(scheme.get, call_606906.host, call_606906.base,
                         call_606906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606906, url, valid)

proc call*(call_606907: Call_TagResource_606894; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_606908 = newJObject()
  var body_606909 = newJObject()
  add(path_606908, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606909 = body
  result = call_606907.call(path_606908, nil, nil, nil, body_606909)

var tagResource* = Call_TagResource_606894(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "backup.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606895,
                                        base: "/", url: url_TagResource_606896,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606910 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606912(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606911(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606913 = path.getOrDefault("resourceArn")
  valid_606913 = validateParameter(valid_606913, JString, required = true,
                                 default = nil)
  if valid_606913 != nil:
    section.add "resourceArn", valid_606913
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
  var valid_606914 = header.getOrDefault("X-Amz-Signature")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Signature", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Content-Sha256", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Date")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Date", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Credential")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Credential", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Security-Token")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Security-Token", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Algorithm")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Algorithm", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-SignedHeaders", valid_606920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606922: Call_UntagResource_606910; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  let valid = call_606922.validator(path, query, header, formData, body)
  let scheme = call_606922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606922.url(scheme.get, call_606922.host, call_606922.base,
                         call_606922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606922, url, valid)

proc call*(call_606923: Call_UntagResource_606910; resourceArn: string;
          body: JsonNode): Recallable =
  ## untagResource
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_606924 = newJObject()
  var body_606925 = newJObject()
  add(path_606924, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606925 = body
  result = call_606923.call(path_606924, nil, nil, nil, body_606925)

var untagResource* = Call_UntagResource_606910(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/untag/{resourceArn}", validator: validate_UntagResource_606911,
    base: "/", url: url_UntagResource_606912, schemes: {Scheme.Https, Scheme.Http})
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
