
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

  OpenApiRestCall_604389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_604389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_604389): Option[Scheme] {.used.} =
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
  Call_CreateBackupPlan_604987 = ref object of OpenApiRestCall_604389
proc url_CreateBackupPlan_604989(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupPlan_604988(path: JsonNode; query: JsonNode;
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
  var valid_604990 = header.getOrDefault("X-Amz-Signature")
  valid_604990 = validateParameter(valid_604990, JString, required = false,
                                 default = nil)
  if valid_604990 != nil:
    section.add "X-Amz-Signature", valid_604990
  var valid_604991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604991 = validateParameter(valid_604991, JString, required = false,
                                 default = nil)
  if valid_604991 != nil:
    section.add "X-Amz-Content-Sha256", valid_604991
  var valid_604992 = header.getOrDefault("X-Amz-Date")
  valid_604992 = validateParameter(valid_604992, JString, required = false,
                                 default = nil)
  if valid_604992 != nil:
    section.add "X-Amz-Date", valid_604992
  var valid_604993 = header.getOrDefault("X-Amz-Credential")
  valid_604993 = validateParameter(valid_604993, JString, required = false,
                                 default = nil)
  if valid_604993 != nil:
    section.add "X-Amz-Credential", valid_604993
  var valid_604994 = header.getOrDefault("X-Amz-Security-Token")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "X-Amz-Security-Token", valid_604994
  var valid_604995 = header.getOrDefault("X-Amz-Algorithm")
  valid_604995 = validateParameter(valid_604995, JString, required = false,
                                 default = nil)
  if valid_604995 != nil:
    section.add "X-Amz-Algorithm", valid_604995
  var valid_604996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604996 = validateParameter(valid_604996, JString, required = false,
                                 default = nil)
  if valid_604996 != nil:
    section.add "X-Amz-SignedHeaders", valid_604996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604998: Call_CreateBackupPlan_604987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ## 
  let valid = call_604998.validator(path, query, header, formData, body)
  let scheme = call_604998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604998.url(scheme.get, call_604998.host, call_604998.base,
                         call_604998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604998, url, valid)

proc call*(call_604999: Call_CreateBackupPlan_604987; body: JsonNode): Recallable =
  ## createBackupPlan
  ## <p>Backup plans are documents that contain information that AWS Backup uses to schedule tasks that create recovery points of resources.</p> <p>If you call <code>CreateBackupPlan</code> with a plan that already exists, an <code>AlreadyExistsException</code> is returned.</p>
  ##   body: JObject (required)
  var body_605000 = newJObject()
  if body != nil:
    body_605000 = body
  result = call_604999.call(nil, nil, nil, nil, body_605000)

var createBackupPlan* = Call_CreateBackupPlan_604987(name: "createBackupPlan",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_CreateBackupPlan_604988, base: "/",
    url: url_CreateBackupPlan_604989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlans_604727 = ref object of OpenApiRestCall_604389
proc url_ListBackupPlans_604729(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlans_604728(path: JsonNode; query: JsonNode;
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
  var valid_604841 = query.getOrDefault("nextToken")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "nextToken", valid_604841
  var valid_604842 = query.getOrDefault("MaxResults")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "MaxResults", valid_604842
  var valid_604843 = query.getOrDefault("NextToken")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "NextToken", valid_604843
  var valid_604844 = query.getOrDefault("includeDeleted")
  valid_604844 = validateParameter(valid_604844, JBool, required = false, default = nil)
  if valid_604844 != nil:
    section.add "includeDeleted", valid_604844
  var valid_604845 = query.getOrDefault("maxResults")
  valid_604845 = validateParameter(valid_604845, JInt, required = false, default = nil)
  if valid_604845 != nil:
    section.add "maxResults", valid_604845
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
  var valid_604846 = header.getOrDefault("X-Amz-Signature")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Signature", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-Content-Sha256", valid_604847
  var valid_604848 = header.getOrDefault("X-Amz-Date")
  valid_604848 = validateParameter(valid_604848, JString, required = false,
                                 default = nil)
  if valid_604848 != nil:
    section.add "X-Amz-Date", valid_604848
  var valid_604849 = header.getOrDefault("X-Amz-Credential")
  valid_604849 = validateParameter(valid_604849, JString, required = false,
                                 default = nil)
  if valid_604849 != nil:
    section.add "X-Amz-Credential", valid_604849
  var valid_604850 = header.getOrDefault("X-Amz-Security-Token")
  valid_604850 = validateParameter(valid_604850, JString, required = false,
                                 default = nil)
  if valid_604850 != nil:
    section.add "X-Amz-Security-Token", valid_604850
  var valid_604851 = header.getOrDefault("X-Amz-Algorithm")
  valid_604851 = validateParameter(valid_604851, JString, required = false,
                                 default = nil)
  if valid_604851 != nil:
    section.add "X-Amz-Algorithm", valid_604851
  var valid_604852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604852 = validateParameter(valid_604852, JString, required = false,
                                 default = nil)
  if valid_604852 != nil:
    section.add "X-Amz-SignedHeaders", valid_604852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604875: Call_ListBackupPlans_604727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plans, including Amazon Resource Names (ARNs), plan IDs, creation and deletion dates, version IDs, plan names, and creator request IDs.
  ## 
  let valid = call_604875.validator(path, query, header, formData, body)
  let scheme = call_604875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604875.url(scheme.get, call_604875.host, call_604875.base,
                         call_604875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604875, url, valid)

proc call*(call_604946: Call_ListBackupPlans_604727; nextToken: string = "";
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
  var query_604947 = newJObject()
  add(query_604947, "nextToken", newJString(nextToken))
  add(query_604947, "MaxResults", newJString(MaxResults))
  add(query_604947, "NextToken", newJString(NextToken))
  add(query_604947, "includeDeleted", newJBool(includeDeleted))
  add(query_604947, "maxResults", newJInt(maxResults))
  result = call_604946.call(nil, query_604947, nil, nil, nil)

var listBackupPlans* = Call_ListBackupPlans_604727(name: "listBackupPlans",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup/plans/",
    validator: validate_ListBackupPlans_604728, base: "/", url: url_ListBackupPlans_604729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupSelection_605034 = ref object of OpenApiRestCall_604389
proc url_CreateBackupSelection_605036(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupSelection_605035(path: JsonNode; query: JsonNode;
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
  var valid_605037 = path.getOrDefault("backupPlanId")
  valid_605037 = validateParameter(valid_605037, JString, required = true,
                                 default = nil)
  if valid_605037 != nil:
    section.add "backupPlanId", valid_605037
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
  var valid_605038 = header.getOrDefault("X-Amz-Signature")
  valid_605038 = validateParameter(valid_605038, JString, required = false,
                                 default = nil)
  if valid_605038 != nil:
    section.add "X-Amz-Signature", valid_605038
  var valid_605039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605039 = validateParameter(valid_605039, JString, required = false,
                                 default = nil)
  if valid_605039 != nil:
    section.add "X-Amz-Content-Sha256", valid_605039
  var valid_605040 = header.getOrDefault("X-Amz-Date")
  valid_605040 = validateParameter(valid_605040, JString, required = false,
                                 default = nil)
  if valid_605040 != nil:
    section.add "X-Amz-Date", valid_605040
  var valid_605041 = header.getOrDefault("X-Amz-Credential")
  valid_605041 = validateParameter(valid_605041, JString, required = false,
                                 default = nil)
  if valid_605041 != nil:
    section.add "X-Amz-Credential", valid_605041
  var valid_605042 = header.getOrDefault("X-Amz-Security-Token")
  valid_605042 = validateParameter(valid_605042, JString, required = false,
                                 default = nil)
  if valid_605042 != nil:
    section.add "X-Amz-Security-Token", valid_605042
  var valid_605043 = header.getOrDefault("X-Amz-Algorithm")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "X-Amz-Algorithm", valid_605043
  var valid_605044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605044 = validateParameter(valid_605044, JString, required = false,
                                 default = nil)
  if valid_605044 != nil:
    section.add "X-Amz-SignedHeaders", valid_605044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605046: Call_CreateBackupSelection_605034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ## 
  let valid = call_605046.validator(path, query, header, formData, body)
  let scheme = call_605046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605046.url(scheme.get, call_605046.host, call_605046.base,
                         call_605046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605046, url, valid)

proc call*(call_605047: Call_CreateBackupSelection_605034; backupPlanId: string;
          body: JsonNode): Recallable =
  ## createBackupSelection
  ## <p>Creates a JSON document that specifies a set of resources to assign to a backup plan. Resources can be included by specifying patterns for a <code>ListOfTags</code> and selected <code>Resources</code>. </p> <p>For example, consider the following patterns:</p> <ul> <li> <p> <code>Resources: "arn:aws:ec2:region:account-id:volume/volume-id"</code> </p> </li> <li> <p> <code>ConditionKey:"department"</code> </p> <p> <code>ConditionValue:"finance"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> <li> <p> <code>ConditionKey:"importance"</code> </p> <p> <code>ConditionValue:"critical"</code> </p> <p> <code>ConditionType:"STRINGEQUALS"</code> </p> </li> </ul> <p>Using these patterns would back up all Amazon Elastic Block Store (Amazon EBS) volumes that are tagged as <code>"department=finance"</code>, <code>"importance=critical"</code>, in addition to an EBS volume with the specified volume Id.</p> <p>Resources and conditions are additive in that all resources that match the pattern are selected. This shouldn't be confused with a logical AND, where all conditions must match. The matching patterns are logically 'put together using the OR operator. In other words, all patterns that match are selected for backup.</p>
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies the backup plan to be associated with the selection of resources.
  ##   body: JObject (required)
  var path_605048 = newJObject()
  var body_605049 = newJObject()
  add(path_605048, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_605049 = body
  result = call_605047.call(path_605048, nil, nil, nil, body_605049)

var createBackupSelection* = Call_CreateBackupSelection_605034(
    name: "createBackupSelection", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_CreateBackupSelection_605035, base: "/",
    url: url_CreateBackupSelection_605036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupSelections_605001 = ref object of OpenApiRestCall_604389
proc url_ListBackupSelections_605003(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupSelections_605002(path: JsonNode; query: JsonNode;
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
  var valid_605018 = path.getOrDefault("backupPlanId")
  valid_605018 = validateParameter(valid_605018, JString, required = true,
                                 default = nil)
  if valid_605018 != nil:
    section.add "backupPlanId", valid_605018
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
  var valid_605019 = query.getOrDefault("nextToken")
  valid_605019 = validateParameter(valid_605019, JString, required = false,
                                 default = nil)
  if valid_605019 != nil:
    section.add "nextToken", valid_605019
  var valid_605020 = query.getOrDefault("MaxResults")
  valid_605020 = validateParameter(valid_605020, JString, required = false,
                                 default = nil)
  if valid_605020 != nil:
    section.add "MaxResults", valid_605020
  var valid_605021 = query.getOrDefault("NextToken")
  valid_605021 = validateParameter(valid_605021, JString, required = false,
                                 default = nil)
  if valid_605021 != nil:
    section.add "NextToken", valid_605021
  var valid_605022 = query.getOrDefault("maxResults")
  valid_605022 = validateParameter(valid_605022, JInt, required = false, default = nil)
  if valid_605022 != nil:
    section.add "maxResults", valid_605022
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
  var valid_605023 = header.getOrDefault("X-Amz-Signature")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "X-Amz-Signature", valid_605023
  var valid_605024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605024 = validateParameter(valid_605024, JString, required = false,
                                 default = nil)
  if valid_605024 != nil:
    section.add "X-Amz-Content-Sha256", valid_605024
  var valid_605025 = header.getOrDefault("X-Amz-Date")
  valid_605025 = validateParameter(valid_605025, JString, required = false,
                                 default = nil)
  if valid_605025 != nil:
    section.add "X-Amz-Date", valid_605025
  var valid_605026 = header.getOrDefault("X-Amz-Credential")
  valid_605026 = validateParameter(valid_605026, JString, required = false,
                                 default = nil)
  if valid_605026 != nil:
    section.add "X-Amz-Credential", valid_605026
  var valid_605027 = header.getOrDefault("X-Amz-Security-Token")
  valid_605027 = validateParameter(valid_605027, JString, required = false,
                                 default = nil)
  if valid_605027 != nil:
    section.add "X-Amz-Security-Token", valid_605027
  var valid_605028 = header.getOrDefault("X-Amz-Algorithm")
  valid_605028 = validateParameter(valid_605028, JString, required = false,
                                 default = nil)
  if valid_605028 != nil:
    section.add "X-Amz-Algorithm", valid_605028
  var valid_605029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605029 = validateParameter(valid_605029, JString, required = false,
                                 default = nil)
  if valid_605029 != nil:
    section.add "X-Amz-SignedHeaders", valid_605029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605030: Call_ListBackupSelections_605001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array containing metadata of the resources associated with the target backup plan.
  ## 
  let valid = call_605030.validator(path, query, header, formData, body)
  let scheme = call_605030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605030.url(scheme.get, call_605030.host, call_605030.base,
                         call_605030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605030, url, valid)

proc call*(call_605031: Call_ListBackupSelections_605001; backupPlanId: string;
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
  var path_605032 = newJObject()
  var query_605033 = newJObject()
  add(query_605033, "nextToken", newJString(nextToken))
  add(query_605033, "MaxResults", newJString(MaxResults))
  add(query_605033, "NextToken", newJString(NextToken))
  add(path_605032, "backupPlanId", newJString(backupPlanId))
  add(query_605033, "maxResults", newJInt(maxResults))
  result = call_605031.call(path_605032, query_605033, nil, nil, nil)

var listBackupSelections* = Call_ListBackupSelections_605001(
    name: "listBackupSelections", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/",
    validator: validate_ListBackupSelections_605002, base: "/",
    url: url_ListBackupSelections_605003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBackupVault_605064 = ref object of OpenApiRestCall_604389
proc url_CreateBackupVault_605066(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBackupVault_605065(path: JsonNode; query: JsonNode;
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
  var valid_605067 = path.getOrDefault("backupVaultName")
  valid_605067 = validateParameter(valid_605067, JString, required = true,
                                 default = nil)
  if valid_605067 != nil:
    section.add "backupVaultName", valid_605067
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
  var valid_605068 = header.getOrDefault("X-Amz-Signature")
  valid_605068 = validateParameter(valid_605068, JString, required = false,
                                 default = nil)
  if valid_605068 != nil:
    section.add "X-Amz-Signature", valid_605068
  var valid_605069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605069 = validateParameter(valid_605069, JString, required = false,
                                 default = nil)
  if valid_605069 != nil:
    section.add "X-Amz-Content-Sha256", valid_605069
  var valid_605070 = header.getOrDefault("X-Amz-Date")
  valid_605070 = validateParameter(valid_605070, JString, required = false,
                                 default = nil)
  if valid_605070 != nil:
    section.add "X-Amz-Date", valid_605070
  var valid_605071 = header.getOrDefault("X-Amz-Credential")
  valid_605071 = validateParameter(valid_605071, JString, required = false,
                                 default = nil)
  if valid_605071 != nil:
    section.add "X-Amz-Credential", valid_605071
  var valid_605072 = header.getOrDefault("X-Amz-Security-Token")
  valid_605072 = validateParameter(valid_605072, JString, required = false,
                                 default = nil)
  if valid_605072 != nil:
    section.add "X-Amz-Security-Token", valid_605072
  var valid_605073 = header.getOrDefault("X-Amz-Algorithm")
  valid_605073 = validateParameter(valid_605073, JString, required = false,
                                 default = nil)
  if valid_605073 != nil:
    section.add "X-Amz-Algorithm", valid_605073
  var valid_605074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605074 = validateParameter(valid_605074, JString, required = false,
                                 default = nil)
  if valid_605074 != nil:
    section.add "X-Amz-SignedHeaders", valid_605074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605076: Call_CreateBackupVault_605064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ## 
  let valid = call_605076.validator(path, query, header, formData, body)
  let scheme = call_605076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605076.url(scheme.get, call_605076.host, call_605076.base,
                         call_605076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605076, url, valid)

proc call*(call_605077: Call_CreateBackupVault_605064; backupVaultName: string;
          body: JsonNode): Recallable =
  ## createBackupVault
  ## <p>Creates a logical container where backups are stored. A <code>CreateBackupVault</code> request includes a name, optionally one or more resource tags, an encryption key, and a request ID.</p> <note> <p>Sensitive data, such as passport numbers, should not be included the name of a backup vault.</p> </note>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_605078 = newJObject()
  var body_605079 = newJObject()
  add(path_605078, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_605079 = body
  result = call_605077.call(path_605078, nil, nil, nil, body_605079)

var createBackupVault* = Call_CreateBackupVault_605064(name: "createBackupVault",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_CreateBackupVault_605065, base: "/",
    url: url_CreateBackupVault_605066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupVault_605050 = ref object of OpenApiRestCall_604389
proc url_DescribeBackupVault_605052(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBackupVault_605051(path: JsonNode; query: JsonNode;
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
  var valid_605053 = path.getOrDefault("backupVaultName")
  valid_605053 = validateParameter(valid_605053, JString, required = true,
                                 default = nil)
  if valid_605053 != nil:
    section.add "backupVaultName", valid_605053
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
  var valid_605054 = header.getOrDefault("X-Amz-Signature")
  valid_605054 = validateParameter(valid_605054, JString, required = false,
                                 default = nil)
  if valid_605054 != nil:
    section.add "X-Amz-Signature", valid_605054
  var valid_605055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605055 = validateParameter(valid_605055, JString, required = false,
                                 default = nil)
  if valid_605055 != nil:
    section.add "X-Amz-Content-Sha256", valid_605055
  var valid_605056 = header.getOrDefault("X-Amz-Date")
  valid_605056 = validateParameter(valid_605056, JString, required = false,
                                 default = nil)
  if valid_605056 != nil:
    section.add "X-Amz-Date", valid_605056
  var valid_605057 = header.getOrDefault("X-Amz-Credential")
  valid_605057 = validateParameter(valid_605057, JString, required = false,
                                 default = nil)
  if valid_605057 != nil:
    section.add "X-Amz-Credential", valid_605057
  var valid_605058 = header.getOrDefault("X-Amz-Security-Token")
  valid_605058 = validateParameter(valid_605058, JString, required = false,
                                 default = nil)
  if valid_605058 != nil:
    section.add "X-Amz-Security-Token", valid_605058
  var valid_605059 = header.getOrDefault("X-Amz-Algorithm")
  valid_605059 = validateParameter(valid_605059, JString, required = false,
                                 default = nil)
  if valid_605059 != nil:
    section.add "X-Amz-Algorithm", valid_605059
  var valid_605060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605060 = validateParameter(valid_605060, JString, required = false,
                                 default = nil)
  if valid_605060 != nil:
    section.add "X-Amz-SignedHeaders", valid_605060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605061: Call_DescribeBackupVault_605050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a backup vault specified by its name.
  ## 
  let valid = call_605061.validator(path, query, header, formData, body)
  let scheme = call_605061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605061.url(scheme.get, call_605061.host, call_605061.base,
                         call_605061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605061, url, valid)

proc call*(call_605062: Call_DescribeBackupVault_605050; backupVaultName: string): Recallable =
  ## describeBackupVault
  ## Returns metadata about a backup vault specified by its name.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_605063 = newJObject()
  add(path_605063, "backupVaultName", newJString(backupVaultName))
  result = call_605062.call(path_605063, nil, nil, nil, nil)

var describeBackupVault* = Call_DescribeBackupVault_605050(
    name: "describeBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}",
    validator: validate_DescribeBackupVault_605051, base: "/",
    url: url_DescribeBackupVault_605052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVault_605080 = ref object of OpenApiRestCall_604389
proc url_DeleteBackupVault_605082(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupVault_605081(path: JsonNode; query: JsonNode;
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
  var valid_605083 = path.getOrDefault("backupVaultName")
  valid_605083 = validateParameter(valid_605083, JString, required = true,
                                 default = nil)
  if valid_605083 != nil:
    section.add "backupVaultName", valid_605083
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
  var valid_605084 = header.getOrDefault("X-Amz-Signature")
  valid_605084 = validateParameter(valid_605084, JString, required = false,
                                 default = nil)
  if valid_605084 != nil:
    section.add "X-Amz-Signature", valid_605084
  var valid_605085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605085 = validateParameter(valid_605085, JString, required = false,
                                 default = nil)
  if valid_605085 != nil:
    section.add "X-Amz-Content-Sha256", valid_605085
  var valid_605086 = header.getOrDefault("X-Amz-Date")
  valid_605086 = validateParameter(valid_605086, JString, required = false,
                                 default = nil)
  if valid_605086 != nil:
    section.add "X-Amz-Date", valid_605086
  var valid_605087 = header.getOrDefault("X-Amz-Credential")
  valid_605087 = validateParameter(valid_605087, JString, required = false,
                                 default = nil)
  if valid_605087 != nil:
    section.add "X-Amz-Credential", valid_605087
  var valid_605088 = header.getOrDefault("X-Amz-Security-Token")
  valid_605088 = validateParameter(valid_605088, JString, required = false,
                                 default = nil)
  if valid_605088 != nil:
    section.add "X-Amz-Security-Token", valid_605088
  var valid_605089 = header.getOrDefault("X-Amz-Algorithm")
  valid_605089 = validateParameter(valid_605089, JString, required = false,
                                 default = nil)
  if valid_605089 != nil:
    section.add "X-Amz-Algorithm", valid_605089
  var valid_605090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605090 = validateParameter(valid_605090, JString, required = false,
                                 default = nil)
  if valid_605090 != nil:
    section.add "X-Amz-SignedHeaders", valid_605090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605091: Call_DeleteBackupVault_605080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ## 
  let valid = call_605091.validator(path, query, header, formData, body)
  let scheme = call_605091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605091.url(scheme.get, call_605091.host, call_605091.base,
                         call_605091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605091, url, valid)

proc call*(call_605092: Call_DeleteBackupVault_605080; backupVaultName: string): Recallable =
  ## deleteBackupVault
  ## Deletes the backup vault identified by its name. A vault can be deleted only if it is empty.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and theAWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_605093 = newJObject()
  add(path_605093, "backupVaultName", newJString(backupVaultName))
  result = call_605092.call(path_605093, nil, nil, nil, nil)

var deleteBackupVault* = Call_DeleteBackupVault_605080(name: "deleteBackupVault",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}",
    validator: validate_DeleteBackupVault_605081, base: "/",
    url: url_DeleteBackupVault_605082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBackupPlan_605094 = ref object of OpenApiRestCall_604389
proc url_UpdateBackupPlan_605096(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateBackupPlan_605095(path: JsonNode; query: JsonNode;
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
  var valid_605097 = path.getOrDefault("backupPlanId")
  valid_605097 = validateParameter(valid_605097, JString, required = true,
                                 default = nil)
  if valid_605097 != nil:
    section.add "backupPlanId", valid_605097
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
  var valid_605098 = header.getOrDefault("X-Amz-Signature")
  valid_605098 = validateParameter(valid_605098, JString, required = false,
                                 default = nil)
  if valid_605098 != nil:
    section.add "X-Amz-Signature", valid_605098
  var valid_605099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605099 = validateParameter(valid_605099, JString, required = false,
                                 default = nil)
  if valid_605099 != nil:
    section.add "X-Amz-Content-Sha256", valid_605099
  var valid_605100 = header.getOrDefault("X-Amz-Date")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "X-Amz-Date", valid_605100
  var valid_605101 = header.getOrDefault("X-Amz-Credential")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "X-Amz-Credential", valid_605101
  var valid_605102 = header.getOrDefault("X-Amz-Security-Token")
  valid_605102 = validateParameter(valid_605102, JString, required = false,
                                 default = nil)
  if valid_605102 != nil:
    section.add "X-Amz-Security-Token", valid_605102
  var valid_605103 = header.getOrDefault("X-Amz-Algorithm")
  valid_605103 = validateParameter(valid_605103, JString, required = false,
                                 default = nil)
  if valid_605103 != nil:
    section.add "X-Amz-Algorithm", valid_605103
  var valid_605104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605104 = validateParameter(valid_605104, JString, required = false,
                                 default = nil)
  if valid_605104 != nil:
    section.add "X-Amz-SignedHeaders", valid_605104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605106: Call_UpdateBackupPlan_605094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ## 
  let valid = call_605106.validator(path, query, header, formData, body)
  let scheme = call_605106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605106.url(scheme.get, call_605106.host, call_605106.base,
                         call_605106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605106, url, valid)

proc call*(call_605107: Call_UpdateBackupPlan_605094; backupPlanId: string;
          body: JsonNode): Recallable =
  ## updateBackupPlan
  ## Replaces the body of a saved backup plan identified by its <code>backupPlanId</code> with the input document in JSON format. The new version is uniquely identified by a <code>VersionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   body: JObject (required)
  var path_605108 = newJObject()
  var body_605109 = newJObject()
  add(path_605108, "backupPlanId", newJString(backupPlanId))
  if body != nil:
    body_605109 = body
  result = call_605107.call(path_605108, nil, nil, nil, body_605109)

var updateBackupPlan* = Call_UpdateBackupPlan_605094(name: "updateBackupPlan",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_UpdateBackupPlan_605095,
    base: "/", url: url_UpdateBackupPlan_605096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupPlan_605110 = ref object of OpenApiRestCall_604389
proc url_DeleteBackupPlan_605112(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupPlan_605111(path: JsonNode; query: JsonNode;
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
  var valid_605113 = path.getOrDefault("backupPlanId")
  valid_605113 = validateParameter(valid_605113, JString, required = true,
                                 default = nil)
  if valid_605113 != nil:
    section.add "backupPlanId", valid_605113
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
  var valid_605114 = header.getOrDefault("X-Amz-Signature")
  valid_605114 = validateParameter(valid_605114, JString, required = false,
                                 default = nil)
  if valid_605114 != nil:
    section.add "X-Amz-Signature", valid_605114
  var valid_605115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605115 = validateParameter(valid_605115, JString, required = false,
                                 default = nil)
  if valid_605115 != nil:
    section.add "X-Amz-Content-Sha256", valid_605115
  var valid_605116 = header.getOrDefault("X-Amz-Date")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-Date", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-Credential")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-Credential", valid_605117
  var valid_605118 = header.getOrDefault("X-Amz-Security-Token")
  valid_605118 = validateParameter(valid_605118, JString, required = false,
                                 default = nil)
  if valid_605118 != nil:
    section.add "X-Amz-Security-Token", valid_605118
  var valid_605119 = header.getOrDefault("X-Amz-Algorithm")
  valid_605119 = validateParameter(valid_605119, JString, required = false,
                                 default = nil)
  if valid_605119 != nil:
    section.add "X-Amz-Algorithm", valid_605119
  var valid_605120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605120 = validateParameter(valid_605120, JString, required = false,
                                 default = nil)
  if valid_605120 != nil:
    section.add "X-Amz-SignedHeaders", valid_605120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605121: Call_DeleteBackupPlan_605110; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ## 
  let valid = call_605121.validator(path, query, header, formData, body)
  let scheme = call_605121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605121.url(scheme.get, call_605121.host, call_605121.base,
                         call_605121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605121, url, valid)

proc call*(call_605122: Call_DeleteBackupPlan_605110; backupPlanId: string): Recallable =
  ## deleteBackupPlan
  ## Deletes a backup plan. A backup plan can only be deleted after all associated selections of resources have been deleted. Deleting a backup plan deletes the current version of a backup plan. Previous versions, if any, will still exist.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_605123 = newJObject()
  add(path_605123, "backupPlanId", newJString(backupPlanId))
  result = call_605122.call(path_605123, nil, nil, nil, nil)

var deleteBackupPlan* = Call_DeleteBackupPlan_605110(name: "deleteBackupPlan",
    meth: HttpMethod.HttpDelete, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}", validator: validate_DeleteBackupPlan_605111,
    base: "/", url: url_DeleteBackupPlan_605112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupSelection_605124 = ref object of OpenApiRestCall_604389
proc url_GetBackupSelection_605126(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupSelection_605125(path: JsonNode; query: JsonNode;
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
  var valid_605127 = path.getOrDefault("backupPlanId")
  valid_605127 = validateParameter(valid_605127, JString, required = true,
                                 default = nil)
  if valid_605127 != nil:
    section.add "backupPlanId", valid_605127
  var valid_605128 = path.getOrDefault("selectionId")
  valid_605128 = validateParameter(valid_605128, JString, required = true,
                                 default = nil)
  if valid_605128 != nil:
    section.add "selectionId", valid_605128
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
  var valid_605129 = header.getOrDefault("X-Amz-Signature")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "X-Amz-Signature", valid_605129
  var valid_605130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "X-Amz-Content-Sha256", valid_605130
  var valid_605131 = header.getOrDefault("X-Amz-Date")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "X-Amz-Date", valid_605131
  var valid_605132 = header.getOrDefault("X-Amz-Credential")
  valid_605132 = validateParameter(valid_605132, JString, required = false,
                                 default = nil)
  if valid_605132 != nil:
    section.add "X-Amz-Credential", valid_605132
  var valid_605133 = header.getOrDefault("X-Amz-Security-Token")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "X-Amz-Security-Token", valid_605133
  var valid_605134 = header.getOrDefault("X-Amz-Algorithm")
  valid_605134 = validateParameter(valid_605134, JString, required = false,
                                 default = nil)
  if valid_605134 != nil:
    section.add "X-Amz-Algorithm", valid_605134
  var valid_605135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605135 = validateParameter(valid_605135, JString, required = false,
                                 default = nil)
  if valid_605135 != nil:
    section.add "X-Amz-SignedHeaders", valid_605135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605136: Call_GetBackupSelection_605124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ## 
  let valid = call_605136.validator(path, query, header, formData, body)
  let scheme = call_605136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605136.url(scheme.get, call_605136.host, call_605136.base,
                         call_605136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605136, url, valid)

proc call*(call_605137: Call_GetBackupSelection_605124; backupPlanId: string;
          selectionId: string): Recallable =
  ## getBackupSelection
  ## Returns selection metadata and a document in JSON format that specifies a list of resources that are associated with a backup plan.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_605138 = newJObject()
  add(path_605138, "backupPlanId", newJString(backupPlanId))
  add(path_605138, "selectionId", newJString(selectionId))
  result = call_605137.call(path_605138, nil, nil, nil, nil)

var getBackupSelection* = Call_GetBackupSelection_605124(
    name: "getBackupSelection", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_GetBackupSelection_605125, base: "/",
    url: url_GetBackupSelection_605126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupSelection_605139 = ref object of OpenApiRestCall_604389
proc url_DeleteBackupSelection_605141(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBackupSelection_605140(path: JsonNode; query: JsonNode;
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
  var valid_605142 = path.getOrDefault("backupPlanId")
  valid_605142 = validateParameter(valid_605142, JString, required = true,
                                 default = nil)
  if valid_605142 != nil:
    section.add "backupPlanId", valid_605142
  var valid_605143 = path.getOrDefault("selectionId")
  valid_605143 = validateParameter(valid_605143, JString, required = true,
                                 default = nil)
  if valid_605143 != nil:
    section.add "selectionId", valid_605143
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
  var valid_605144 = header.getOrDefault("X-Amz-Signature")
  valid_605144 = validateParameter(valid_605144, JString, required = false,
                                 default = nil)
  if valid_605144 != nil:
    section.add "X-Amz-Signature", valid_605144
  var valid_605145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605145 = validateParameter(valid_605145, JString, required = false,
                                 default = nil)
  if valid_605145 != nil:
    section.add "X-Amz-Content-Sha256", valid_605145
  var valid_605146 = header.getOrDefault("X-Amz-Date")
  valid_605146 = validateParameter(valid_605146, JString, required = false,
                                 default = nil)
  if valid_605146 != nil:
    section.add "X-Amz-Date", valid_605146
  var valid_605147 = header.getOrDefault("X-Amz-Credential")
  valid_605147 = validateParameter(valid_605147, JString, required = false,
                                 default = nil)
  if valid_605147 != nil:
    section.add "X-Amz-Credential", valid_605147
  var valid_605148 = header.getOrDefault("X-Amz-Security-Token")
  valid_605148 = validateParameter(valid_605148, JString, required = false,
                                 default = nil)
  if valid_605148 != nil:
    section.add "X-Amz-Security-Token", valid_605148
  var valid_605149 = header.getOrDefault("X-Amz-Algorithm")
  valid_605149 = validateParameter(valid_605149, JString, required = false,
                                 default = nil)
  if valid_605149 != nil:
    section.add "X-Amz-Algorithm", valid_605149
  var valid_605150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605150 = validateParameter(valid_605150, JString, required = false,
                                 default = nil)
  if valid_605150 != nil:
    section.add "X-Amz-SignedHeaders", valid_605150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605151: Call_DeleteBackupSelection_605139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ## 
  let valid = call_605151.validator(path, query, header, formData, body)
  let scheme = call_605151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605151.url(scheme.get, call_605151.host, call_605151.base,
                         call_605151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605151, url, valid)

proc call*(call_605152: Call_DeleteBackupSelection_605139; backupPlanId: string;
          selectionId: string): Recallable =
  ## deleteBackupSelection
  ## Deletes the resource selection associated with a backup plan that is specified by the <code>SelectionId</code>.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  ##   selectionId: string (required)
  ##              : Uniquely identifies the body of a request to assign a set of resources to a backup plan.
  var path_605153 = newJObject()
  add(path_605153, "backupPlanId", newJString(backupPlanId))
  add(path_605153, "selectionId", newJString(selectionId))
  result = call_605152.call(path_605153, nil, nil, nil, nil)

var deleteBackupSelection* = Call_DeleteBackupSelection_605139(
    name: "deleteBackupSelection", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/selections/{selectionId}",
    validator: validate_DeleteBackupSelection_605140, base: "/",
    url: url_DeleteBackupSelection_605141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultAccessPolicy_605168 = ref object of OpenApiRestCall_604389
proc url_PutBackupVaultAccessPolicy_605170(protocol: Scheme; host: string;
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

proc validate_PutBackupVaultAccessPolicy_605169(path: JsonNode; query: JsonNode;
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
  var valid_605171 = path.getOrDefault("backupVaultName")
  valid_605171 = validateParameter(valid_605171, JString, required = true,
                                 default = nil)
  if valid_605171 != nil:
    section.add "backupVaultName", valid_605171
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
  var valid_605172 = header.getOrDefault("X-Amz-Signature")
  valid_605172 = validateParameter(valid_605172, JString, required = false,
                                 default = nil)
  if valid_605172 != nil:
    section.add "X-Amz-Signature", valid_605172
  var valid_605173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605173 = validateParameter(valid_605173, JString, required = false,
                                 default = nil)
  if valid_605173 != nil:
    section.add "X-Amz-Content-Sha256", valid_605173
  var valid_605174 = header.getOrDefault("X-Amz-Date")
  valid_605174 = validateParameter(valid_605174, JString, required = false,
                                 default = nil)
  if valid_605174 != nil:
    section.add "X-Amz-Date", valid_605174
  var valid_605175 = header.getOrDefault("X-Amz-Credential")
  valid_605175 = validateParameter(valid_605175, JString, required = false,
                                 default = nil)
  if valid_605175 != nil:
    section.add "X-Amz-Credential", valid_605175
  var valid_605176 = header.getOrDefault("X-Amz-Security-Token")
  valid_605176 = validateParameter(valid_605176, JString, required = false,
                                 default = nil)
  if valid_605176 != nil:
    section.add "X-Amz-Security-Token", valid_605176
  var valid_605177 = header.getOrDefault("X-Amz-Algorithm")
  valid_605177 = validateParameter(valid_605177, JString, required = false,
                                 default = nil)
  if valid_605177 != nil:
    section.add "X-Amz-Algorithm", valid_605177
  var valid_605178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605178 = validateParameter(valid_605178, JString, required = false,
                                 default = nil)
  if valid_605178 != nil:
    section.add "X-Amz-SignedHeaders", valid_605178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605180: Call_PutBackupVaultAccessPolicy_605168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ## 
  let valid = call_605180.validator(path, query, header, formData, body)
  let scheme = call_605180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605180.url(scheme.get, call_605180.host, call_605180.base,
                         call_605180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605180, url, valid)

proc call*(call_605181: Call_PutBackupVaultAccessPolicy_605168;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultAccessPolicy
  ## Sets a resource-based policy that is used to manage access permissions on the target backup vault. Requires a backup vault name and an access policy document in JSON format.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_605182 = newJObject()
  var body_605183 = newJObject()
  add(path_605182, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_605183 = body
  result = call_605181.call(path_605182, nil, nil, nil, body_605183)

var putBackupVaultAccessPolicy* = Call_PutBackupVaultAccessPolicy_605168(
    name: "putBackupVaultAccessPolicy", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_PutBackupVaultAccessPolicy_605169, base: "/",
    url: url_PutBackupVaultAccessPolicy_605170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultAccessPolicy_605154 = ref object of OpenApiRestCall_604389
proc url_GetBackupVaultAccessPolicy_605156(protocol: Scheme; host: string;
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

proc validate_GetBackupVaultAccessPolicy_605155(path: JsonNode; query: JsonNode;
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
  var valid_605157 = path.getOrDefault("backupVaultName")
  valid_605157 = validateParameter(valid_605157, JString, required = true,
                                 default = nil)
  if valid_605157 != nil:
    section.add "backupVaultName", valid_605157
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
  var valid_605158 = header.getOrDefault("X-Amz-Signature")
  valid_605158 = validateParameter(valid_605158, JString, required = false,
                                 default = nil)
  if valid_605158 != nil:
    section.add "X-Amz-Signature", valid_605158
  var valid_605159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605159 = validateParameter(valid_605159, JString, required = false,
                                 default = nil)
  if valid_605159 != nil:
    section.add "X-Amz-Content-Sha256", valid_605159
  var valid_605160 = header.getOrDefault("X-Amz-Date")
  valid_605160 = validateParameter(valid_605160, JString, required = false,
                                 default = nil)
  if valid_605160 != nil:
    section.add "X-Amz-Date", valid_605160
  var valid_605161 = header.getOrDefault("X-Amz-Credential")
  valid_605161 = validateParameter(valid_605161, JString, required = false,
                                 default = nil)
  if valid_605161 != nil:
    section.add "X-Amz-Credential", valid_605161
  var valid_605162 = header.getOrDefault("X-Amz-Security-Token")
  valid_605162 = validateParameter(valid_605162, JString, required = false,
                                 default = nil)
  if valid_605162 != nil:
    section.add "X-Amz-Security-Token", valid_605162
  var valid_605163 = header.getOrDefault("X-Amz-Algorithm")
  valid_605163 = validateParameter(valid_605163, JString, required = false,
                                 default = nil)
  if valid_605163 != nil:
    section.add "X-Amz-Algorithm", valid_605163
  var valid_605164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605164 = validateParameter(valid_605164, JString, required = false,
                                 default = nil)
  if valid_605164 != nil:
    section.add "X-Amz-SignedHeaders", valid_605164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605165: Call_GetBackupVaultAccessPolicy_605154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the access policy document that is associated with the named backup vault.
  ## 
  let valid = call_605165.validator(path, query, header, formData, body)
  let scheme = call_605165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605165.url(scheme.get, call_605165.host, call_605165.base,
                         call_605165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605165, url, valid)

proc call*(call_605166: Call_GetBackupVaultAccessPolicy_605154;
          backupVaultName: string): Recallable =
  ## getBackupVaultAccessPolicy
  ## Returns the access policy document that is associated with the named backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_605167 = newJObject()
  add(path_605167, "backupVaultName", newJString(backupVaultName))
  result = call_605166.call(path_605167, nil, nil, nil, nil)

var getBackupVaultAccessPolicy* = Call_GetBackupVaultAccessPolicy_605154(
    name: "getBackupVaultAccessPolicy", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_GetBackupVaultAccessPolicy_605155, base: "/",
    url: url_GetBackupVaultAccessPolicy_605156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultAccessPolicy_605184 = ref object of OpenApiRestCall_604389
proc url_DeleteBackupVaultAccessPolicy_605186(protocol: Scheme; host: string;
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

proc validate_DeleteBackupVaultAccessPolicy_605185(path: JsonNode; query: JsonNode;
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
  var valid_605187 = path.getOrDefault("backupVaultName")
  valid_605187 = validateParameter(valid_605187, JString, required = true,
                                 default = nil)
  if valid_605187 != nil:
    section.add "backupVaultName", valid_605187
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
  var valid_605188 = header.getOrDefault("X-Amz-Signature")
  valid_605188 = validateParameter(valid_605188, JString, required = false,
                                 default = nil)
  if valid_605188 != nil:
    section.add "X-Amz-Signature", valid_605188
  var valid_605189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605189 = validateParameter(valid_605189, JString, required = false,
                                 default = nil)
  if valid_605189 != nil:
    section.add "X-Amz-Content-Sha256", valid_605189
  var valid_605190 = header.getOrDefault("X-Amz-Date")
  valid_605190 = validateParameter(valid_605190, JString, required = false,
                                 default = nil)
  if valid_605190 != nil:
    section.add "X-Amz-Date", valid_605190
  var valid_605191 = header.getOrDefault("X-Amz-Credential")
  valid_605191 = validateParameter(valid_605191, JString, required = false,
                                 default = nil)
  if valid_605191 != nil:
    section.add "X-Amz-Credential", valid_605191
  var valid_605192 = header.getOrDefault("X-Amz-Security-Token")
  valid_605192 = validateParameter(valid_605192, JString, required = false,
                                 default = nil)
  if valid_605192 != nil:
    section.add "X-Amz-Security-Token", valid_605192
  var valid_605193 = header.getOrDefault("X-Amz-Algorithm")
  valid_605193 = validateParameter(valid_605193, JString, required = false,
                                 default = nil)
  if valid_605193 != nil:
    section.add "X-Amz-Algorithm", valid_605193
  var valid_605194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605194 = validateParameter(valid_605194, JString, required = false,
                                 default = nil)
  if valid_605194 != nil:
    section.add "X-Amz-SignedHeaders", valid_605194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605195: Call_DeleteBackupVaultAccessPolicy_605184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the policy document that manages permissions on a backup vault.
  ## 
  let valid = call_605195.validator(path, query, header, formData, body)
  let scheme = call_605195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605195.url(scheme.get, call_605195.host, call_605195.base,
                         call_605195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605195, url, valid)

proc call*(call_605196: Call_DeleteBackupVaultAccessPolicy_605184;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultAccessPolicy
  ## Deletes the policy document that manages permissions on a backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_605197 = newJObject()
  add(path_605197, "backupVaultName", newJString(backupVaultName))
  result = call_605196.call(path_605197, nil, nil, nil, nil)

var deleteBackupVaultAccessPolicy* = Call_DeleteBackupVaultAccessPolicy_605184(
    name: "deleteBackupVaultAccessPolicy", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/access-policy",
    validator: validate_DeleteBackupVaultAccessPolicy_605185, base: "/",
    url: url_DeleteBackupVaultAccessPolicy_605186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBackupVaultNotifications_605212 = ref object of OpenApiRestCall_604389
proc url_PutBackupVaultNotifications_605214(protocol: Scheme; host: string;
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

proc validate_PutBackupVaultNotifications_605213(path: JsonNode; query: JsonNode;
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
  var valid_605215 = path.getOrDefault("backupVaultName")
  valid_605215 = validateParameter(valid_605215, JString, required = true,
                                 default = nil)
  if valid_605215 != nil:
    section.add "backupVaultName", valid_605215
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
  var valid_605216 = header.getOrDefault("X-Amz-Signature")
  valid_605216 = validateParameter(valid_605216, JString, required = false,
                                 default = nil)
  if valid_605216 != nil:
    section.add "X-Amz-Signature", valid_605216
  var valid_605217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605217 = validateParameter(valid_605217, JString, required = false,
                                 default = nil)
  if valid_605217 != nil:
    section.add "X-Amz-Content-Sha256", valid_605217
  var valid_605218 = header.getOrDefault("X-Amz-Date")
  valid_605218 = validateParameter(valid_605218, JString, required = false,
                                 default = nil)
  if valid_605218 != nil:
    section.add "X-Amz-Date", valid_605218
  var valid_605219 = header.getOrDefault("X-Amz-Credential")
  valid_605219 = validateParameter(valid_605219, JString, required = false,
                                 default = nil)
  if valid_605219 != nil:
    section.add "X-Amz-Credential", valid_605219
  var valid_605220 = header.getOrDefault("X-Amz-Security-Token")
  valid_605220 = validateParameter(valid_605220, JString, required = false,
                                 default = nil)
  if valid_605220 != nil:
    section.add "X-Amz-Security-Token", valid_605220
  var valid_605221 = header.getOrDefault("X-Amz-Algorithm")
  valid_605221 = validateParameter(valid_605221, JString, required = false,
                                 default = nil)
  if valid_605221 != nil:
    section.add "X-Amz-Algorithm", valid_605221
  var valid_605222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605222 = validateParameter(valid_605222, JString, required = false,
                                 default = nil)
  if valid_605222 != nil:
    section.add "X-Amz-SignedHeaders", valid_605222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605224: Call_PutBackupVaultNotifications_605212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on notifications on a backup vault for the specified topic and events.
  ## 
  let valid = call_605224.validator(path, query, header, formData, body)
  let scheme = call_605224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605224.url(scheme.get, call_605224.host, call_605224.base,
                         call_605224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605224, url, valid)

proc call*(call_605225: Call_PutBackupVaultNotifications_605212;
          backupVaultName: string; body: JsonNode): Recallable =
  ## putBackupVaultNotifications
  ## Turns on notifications on a backup vault for the specified topic and events.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   body: JObject (required)
  var path_605226 = newJObject()
  var body_605227 = newJObject()
  add(path_605226, "backupVaultName", newJString(backupVaultName))
  if body != nil:
    body_605227 = body
  result = call_605225.call(path_605226, nil, nil, nil, body_605227)

var putBackupVaultNotifications* = Call_PutBackupVaultNotifications_605212(
    name: "putBackupVaultNotifications", meth: HttpMethod.HttpPut,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_PutBackupVaultNotifications_605213, base: "/",
    url: url_PutBackupVaultNotifications_605214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupVaultNotifications_605198 = ref object of OpenApiRestCall_604389
proc url_GetBackupVaultNotifications_605200(protocol: Scheme; host: string;
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

proc validate_GetBackupVaultNotifications_605199(path: JsonNode; query: JsonNode;
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
  var valid_605201 = path.getOrDefault("backupVaultName")
  valid_605201 = validateParameter(valid_605201, JString, required = true,
                                 default = nil)
  if valid_605201 != nil:
    section.add "backupVaultName", valid_605201
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
  var valid_605202 = header.getOrDefault("X-Amz-Signature")
  valid_605202 = validateParameter(valid_605202, JString, required = false,
                                 default = nil)
  if valid_605202 != nil:
    section.add "X-Amz-Signature", valid_605202
  var valid_605203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605203 = validateParameter(valid_605203, JString, required = false,
                                 default = nil)
  if valid_605203 != nil:
    section.add "X-Amz-Content-Sha256", valid_605203
  var valid_605204 = header.getOrDefault("X-Amz-Date")
  valid_605204 = validateParameter(valid_605204, JString, required = false,
                                 default = nil)
  if valid_605204 != nil:
    section.add "X-Amz-Date", valid_605204
  var valid_605205 = header.getOrDefault("X-Amz-Credential")
  valid_605205 = validateParameter(valid_605205, JString, required = false,
                                 default = nil)
  if valid_605205 != nil:
    section.add "X-Amz-Credential", valid_605205
  var valid_605206 = header.getOrDefault("X-Amz-Security-Token")
  valid_605206 = validateParameter(valid_605206, JString, required = false,
                                 default = nil)
  if valid_605206 != nil:
    section.add "X-Amz-Security-Token", valid_605206
  var valid_605207 = header.getOrDefault("X-Amz-Algorithm")
  valid_605207 = validateParameter(valid_605207, JString, required = false,
                                 default = nil)
  if valid_605207 != nil:
    section.add "X-Amz-Algorithm", valid_605207
  var valid_605208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605208 = validateParameter(valid_605208, JString, required = false,
                                 default = nil)
  if valid_605208 != nil:
    section.add "X-Amz-SignedHeaders", valid_605208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605209: Call_GetBackupVaultNotifications_605198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns event notifications for the specified backup vault.
  ## 
  let valid = call_605209.validator(path, query, header, formData, body)
  let scheme = call_605209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605209.url(scheme.get, call_605209.host, call_605209.base,
                         call_605209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605209, url, valid)

proc call*(call_605210: Call_GetBackupVaultNotifications_605198;
          backupVaultName: string): Recallable =
  ## getBackupVaultNotifications
  ## Returns event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_605211 = newJObject()
  add(path_605211, "backupVaultName", newJString(backupVaultName))
  result = call_605210.call(path_605211, nil, nil, nil, nil)

var getBackupVaultNotifications* = Call_GetBackupVaultNotifications_605198(
    name: "getBackupVaultNotifications", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_GetBackupVaultNotifications_605199, base: "/",
    url: url_GetBackupVaultNotifications_605200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBackupVaultNotifications_605228 = ref object of OpenApiRestCall_604389
proc url_DeleteBackupVaultNotifications_605230(protocol: Scheme; host: string;
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

proc validate_DeleteBackupVaultNotifications_605229(path: JsonNode;
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
  var valid_605231 = path.getOrDefault("backupVaultName")
  valid_605231 = validateParameter(valid_605231, JString, required = true,
                                 default = nil)
  if valid_605231 != nil:
    section.add "backupVaultName", valid_605231
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
  var valid_605232 = header.getOrDefault("X-Amz-Signature")
  valid_605232 = validateParameter(valid_605232, JString, required = false,
                                 default = nil)
  if valid_605232 != nil:
    section.add "X-Amz-Signature", valid_605232
  var valid_605233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605233 = validateParameter(valid_605233, JString, required = false,
                                 default = nil)
  if valid_605233 != nil:
    section.add "X-Amz-Content-Sha256", valid_605233
  var valid_605234 = header.getOrDefault("X-Amz-Date")
  valid_605234 = validateParameter(valid_605234, JString, required = false,
                                 default = nil)
  if valid_605234 != nil:
    section.add "X-Amz-Date", valid_605234
  var valid_605235 = header.getOrDefault("X-Amz-Credential")
  valid_605235 = validateParameter(valid_605235, JString, required = false,
                                 default = nil)
  if valid_605235 != nil:
    section.add "X-Amz-Credential", valid_605235
  var valid_605236 = header.getOrDefault("X-Amz-Security-Token")
  valid_605236 = validateParameter(valid_605236, JString, required = false,
                                 default = nil)
  if valid_605236 != nil:
    section.add "X-Amz-Security-Token", valid_605236
  var valid_605237 = header.getOrDefault("X-Amz-Algorithm")
  valid_605237 = validateParameter(valid_605237, JString, required = false,
                                 default = nil)
  if valid_605237 != nil:
    section.add "X-Amz-Algorithm", valid_605237
  var valid_605238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605238 = validateParameter(valid_605238, JString, required = false,
                                 default = nil)
  if valid_605238 != nil:
    section.add "X-Amz-SignedHeaders", valid_605238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605239: Call_DeleteBackupVaultNotifications_605228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes event notifications for the specified backup vault.
  ## 
  let valid = call_605239.validator(path, query, header, formData, body)
  let scheme = call_605239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605239.url(scheme.get, call_605239.host, call_605239.base,
                         call_605239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605239, url, valid)

proc call*(call_605240: Call_DeleteBackupVaultNotifications_605228;
          backupVaultName: string): Recallable =
  ## deleteBackupVaultNotifications
  ## Deletes event notifications for the specified backup vault.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  var path_605241 = newJObject()
  add(path_605241, "backupVaultName", newJString(backupVaultName))
  result = call_605240.call(path_605241, nil, nil, nil, nil)

var deleteBackupVaultNotifications* = Call_DeleteBackupVaultNotifications_605228(
    name: "deleteBackupVaultNotifications", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/notification-configuration",
    validator: validate_DeleteBackupVaultNotifications_605229, base: "/",
    url: url_DeleteBackupVaultNotifications_605230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRecoveryPointLifecycle_605257 = ref object of OpenApiRestCall_604389
proc url_UpdateRecoveryPointLifecycle_605259(protocol: Scheme; host: string;
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

proc validate_UpdateRecoveryPointLifecycle_605258(path: JsonNode; query: JsonNode;
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
  var valid_605260 = path.getOrDefault("backupVaultName")
  valid_605260 = validateParameter(valid_605260, JString, required = true,
                                 default = nil)
  if valid_605260 != nil:
    section.add "backupVaultName", valid_605260
  var valid_605261 = path.getOrDefault("recoveryPointArn")
  valid_605261 = validateParameter(valid_605261, JString, required = true,
                                 default = nil)
  if valid_605261 != nil:
    section.add "recoveryPointArn", valid_605261
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
  var valid_605262 = header.getOrDefault("X-Amz-Signature")
  valid_605262 = validateParameter(valid_605262, JString, required = false,
                                 default = nil)
  if valid_605262 != nil:
    section.add "X-Amz-Signature", valid_605262
  var valid_605263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605263 = validateParameter(valid_605263, JString, required = false,
                                 default = nil)
  if valid_605263 != nil:
    section.add "X-Amz-Content-Sha256", valid_605263
  var valid_605264 = header.getOrDefault("X-Amz-Date")
  valid_605264 = validateParameter(valid_605264, JString, required = false,
                                 default = nil)
  if valid_605264 != nil:
    section.add "X-Amz-Date", valid_605264
  var valid_605265 = header.getOrDefault("X-Amz-Credential")
  valid_605265 = validateParameter(valid_605265, JString, required = false,
                                 default = nil)
  if valid_605265 != nil:
    section.add "X-Amz-Credential", valid_605265
  var valid_605266 = header.getOrDefault("X-Amz-Security-Token")
  valid_605266 = validateParameter(valid_605266, JString, required = false,
                                 default = nil)
  if valid_605266 != nil:
    section.add "X-Amz-Security-Token", valid_605266
  var valid_605267 = header.getOrDefault("X-Amz-Algorithm")
  valid_605267 = validateParameter(valid_605267, JString, required = false,
                                 default = nil)
  if valid_605267 != nil:
    section.add "X-Amz-Algorithm", valid_605267
  var valid_605268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605268 = validateParameter(valid_605268, JString, required = false,
                                 default = nil)
  if valid_605268 != nil:
    section.add "X-Amz-SignedHeaders", valid_605268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605270: Call_UpdateRecoveryPointLifecycle_605257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ## 
  let valid = call_605270.validator(path, query, header, formData, body)
  let scheme = call_605270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605270.url(scheme.get, call_605270.host, call_605270.base,
                         call_605270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605270, url, valid)

proc call*(call_605271: Call_UpdateRecoveryPointLifecycle_605257;
          backupVaultName: string; recoveryPointArn: string; body: JsonNode): Recallable =
  ## updateRecoveryPointLifecycle
  ## <p>Sets the transition lifecycle of a recovery point.</p> <p>The lifecycle defines when a protected resource is transitioned to cold storage and when it expires. AWS Backup transitions and expires backups automatically according to the lifecycle that you define. </p> <p>Backups transitioned to cold storage must be stored in cold storage for a minimum of 90 days. Therefore, the “expire after days” setting must be 90 days greater than the “transition to cold after days” setting. The “transition to cold after days” setting cannot be changed after a backup has been transitioned to cold. </p>
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  ##   body: JObject (required)
  var path_605272 = newJObject()
  var body_605273 = newJObject()
  add(path_605272, "backupVaultName", newJString(backupVaultName))
  add(path_605272, "recoveryPointArn", newJString(recoveryPointArn))
  if body != nil:
    body_605273 = body
  result = call_605271.call(path_605272, nil, nil, nil, body_605273)

var updateRecoveryPointLifecycle* = Call_UpdateRecoveryPointLifecycle_605257(
    name: "updateRecoveryPointLifecycle", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_UpdateRecoveryPointLifecycle_605258, base: "/",
    url: url_UpdateRecoveryPointLifecycle_605259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRecoveryPoint_605242 = ref object of OpenApiRestCall_604389
proc url_DescribeRecoveryPoint_605244(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRecoveryPoint_605243(path: JsonNode; query: JsonNode;
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
  var valid_605245 = path.getOrDefault("backupVaultName")
  valid_605245 = validateParameter(valid_605245, JString, required = true,
                                 default = nil)
  if valid_605245 != nil:
    section.add "backupVaultName", valid_605245
  var valid_605246 = path.getOrDefault("recoveryPointArn")
  valid_605246 = validateParameter(valid_605246, JString, required = true,
                                 default = nil)
  if valid_605246 != nil:
    section.add "recoveryPointArn", valid_605246
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
  var valid_605247 = header.getOrDefault("X-Amz-Signature")
  valid_605247 = validateParameter(valid_605247, JString, required = false,
                                 default = nil)
  if valid_605247 != nil:
    section.add "X-Amz-Signature", valid_605247
  var valid_605248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605248 = validateParameter(valid_605248, JString, required = false,
                                 default = nil)
  if valid_605248 != nil:
    section.add "X-Amz-Content-Sha256", valid_605248
  var valid_605249 = header.getOrDefault("X-Amz-Date")
  valid_605249 = validateParameter(valid_605249, JString, required = false,
                                 default = nil)
  if valid_605249 != nil:
    section.add "X-Amz-Date", valid_605249
  var valid_605250 = header.getOrDefault("X-Amz-Credential")
  valid_605250 = validateParameter(valid_605250, JString, required = false,
                                 default = nil)
  if valid_605250 != nil:
    section.add "X-Amz-Credential", valid_605250
  var valid_605251 = header.getOrDefault("X-Amz-Security-Token")
  valid_605251 = validateParameter(valid_605251, JString, required = false,
                                 default = nil)
  if valid_605251 != nil:
    section.add "X-Amz-Security-Token", valid_605251
  var valid_605252 = header.getOrDefault("X-Amz-Algorithm")
  valid_605252 = validateParameter(valid_605252, JString, required = false,
                                 default = nil)
  if valid_605252 != nil:
    section.add "X-Amz-Algorithm", valid_605252
  var valid_605253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605253 = validateParameter(valid_605253, JString, required = false,
                                 default = nil)
  if valid_605253 != nil:
    section.add "X-Amz-SignedHeaders", valid_605253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605254: Call_DescribeRecoveryPoint_605242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ## 
  let valid = call_605254.validator(path, query, header, formData, body)
  let scheme = call_605254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605254.url(scheme.get, call_605254.host, call_605254.base,
                         call_605254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605254, url, valid)

proc call*(call_605255: Call_DescribeRecoveryPoint_605242; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## describeRecoveryPoint
  ## Returns metadata associated with a recovery point, including ID, status, encryption, and lifecycle.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_605256 = newJObject()
  add(path_605256, "backupVaultName", newJString(backupVaultName))
  add(path_605256, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_605255.call(path_605256, nil, nil, nil, nil)

var describeRecoveryPoint* = Call_DescribeRecoveryPoint_605242(
    name: "describeRecoveryPoint", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DescribeRecoveryPoint_605243, base: "/",
    url: url_DescribeRecoveryPoint_605244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRecoveryPoint_605274 = ref object of OpenApiRestCall_604389
proc url_DeleteRecoveryPoint_605276(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRecoveryPoint_605275(path: JsonNode; query: JsonNode;
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
  var valid_605277 = path.getOrDefault("backupVaultName")
  valid_605277 = validateParameter(valid_605277, JString, required = true,
                                 default = nil)
  if valid_605277 != nil:
    section.add "backupVaultName", valid_605277
  var valid_605278 = path.getOrDefault("recoveryPointArn")
  valid_605278 = validateParameter(valid_605278, JString, required = true,
                                 default = nil)
  if valid_605278 != nil:
    section.add "recoveryPointArn", valid_605278
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
  var valid_605279 = header.getOrDefault("X-Amz-Signature")
  valid_605279 = validateParameter(valid_605279, JString, required = false,
                                 default = nil)
  if valid_605279 != nil:
    section.add "X-Amz-Signature", valid_605279
  var valid_605280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605280 = validateParameter(valid_605280, JString, required = false,
                                 default = nil)
  if valid_605280 != nil:
    section.add "X-Amz-Content-Sha256", valid_605280
  var valid_605281 = header.getOrDefault("X-Amz-Date")
  valid_605281 = validateParameter(valid_605281, JString, required = false,
                                 default = nil)
  if valid_605281 != nil:
    section.add "X-Amz-Date", valid_605281
  var valid_605282 = header.getOrDefault("X-Amz-Credential")
  valid_605282 = validateParameter(valid_605282, JString, required = false,
                                 default = nil)
  if valid_605282 != nil:
    section.add "X-Amz-Credential", valid_605282
  var valid_605283 = header.getOrDefault("X-Amz-Security-Token")
  valid_605283 = validateParameter(valid_605283, JString, required = false,
                                 default = nil)
  if valid_605283 != nil:
    section.add "X-Amz-Security-Token", valid_605283
  var valid_605284 = header.getOrDefault("X-Amz-Algorithm")
  valid_605284 = validateParameter(valid_605284, JString, required = false,
                                 default = nil)
  if valid_605284 != nil:
    section.add "X-Amz-Algorithm", valid_605284
  var valid_605285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605285 = validateParameter(valid_605285, JString, required = false,
                                 default = nil)
  if valid_605285 != nil:
    section.add "X-Amz-SignedHeaders", valid_605285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605286: Call_DeleteRecoveryPoint_605274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the recovery point specified by a recovery point ID.
  ## 
  let valid = call_605286.validator(path, query, header, formData, body)
  let scheme = call_605286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605286.url(scheme.get, call_605286.host, call_605286.base,
                         call_605286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605286, url, valid)

proc call*(call_605287: Call_DeleteRecoveryPoint_605274; backupVaultName: string;
          recoveryPointArn: string): Recallable =
  ## deleteRecoveryPoint
  ## Deletes the recovery point specified by a recovery point ID.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_605288 = newJObject()
  add(path_605288, "backupVaultName", newJString(backupVaultName))
  add(path_605288, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_605287.call(path_605288, nil, nil, nil, nil)

var deleteRecoveryPoint* = Call_DeleteRecoveryPoint_605274(
    name: "deleteRecoveryPoint", meth: HttpMethod.HttpDelete,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}",
    validator: validate_DeleteRecoveryPoint_605275, base: "/",
    url: url_DeleteRecoveryPoint_605276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopBackupJob_605303 = ref object of OpenApiRestCall_604389
proc url_StopBackupJob_605305(protocol: Scheme; host: string; base: string;
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

proc validate_StopBackupJob_605304(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605306 = path.getOrDefault("backupJobId")
  valid_605306 = validateParameter(valid_605306, JString, required = true,
                                 default = nil)
  if valid_605306 != nil:
    section.add "backupJobId", valid_605306
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
  var valid_605307 = header.getOrDefault("X-Amz-Signature")
  valid_605307 = validateParameter(valid_605307, JString, required = false,
                                 default = nil)
  if valid_605307 != nil:
    section.add "X-Amz-Signature", valid_605307
  var valid_605308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605308 = validateParameter(valid_605308, JString, required = false,
                                 default = nil)
  if valid_605308 != nil:
    section.add "X-Amz-Content-Sha256", valid_605308
  var valid_605309 = header.getOrDefault("X-Amz-Date")
  valid_605309 = validateParameter(valid_605309, JString, required = false,
                                 default = nil)
  if valid_605309 != nil:
    section.add "X-Amz-Date", valid_605309
  var valid_605310 = header.getOrDefault("X-Amz-Credential")
  valid_605310 = validateParameter(valid_605310, JString, required = false,
                                 default = nil)
  if valid_605310 != nil:
    section.add "X-Amz-Credential", valid_605310
  var valid_605311 = header.getOrDefault("X-Amz-Security-Token")
  valid_605311 = validateParameter(valid_605311, JString, required = false,
                                 default = nil)
  if valid_605311 != nil:
    section.add "X-Amz-Security-Token", valid_605311
  var valid_605312 = header.getOrDefault("X-Amz-Algorithm")
  valid_605312 = validateParameter(valid_605312, JString, required = false,
                                 default = nil)
  if valid_605312 != nil:
    section.add "X-Amz-Algorithm", valid_605312
  var valid_605313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605313 = validateParameter(valid_605313, JString, required = false,
                                 default = nil)
  if valid_605313 != nil:
    section.add "X-Amz-SignedHeaders", valid_605313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605314: Call_StopBackupJob_605303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ## 
  let valid = call_605314.validator(path, query, header, formData, body)
  let scheme = call_605314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605314.url(scheme.get, call_605314.host, call_605314.base,
                         call_605314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605314, url, valid)

proc call*(call_605315: Call_StopBackupJob_605303; backupJobId: string): Recallable =
  ## stopBackupJob
  ## Attempts to cancel a job to create a one-time backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_605316 = newJObject()
  add(path_605316, "backupJobId", newJString(backupJobId))
  result = call_605315.call(path_605316, nil, nil, nil, nil)

var stopBackupJob* = Call_StopBackupJob_605303(name: "stopBackupJob",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_StopBackupJob_605304,
    base: "/", url: url_StopBackupJob_605305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBackupJob_605289 = ref object of OpenApiRestCall_604389
proc url_DescribeBackupJob_605291(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeBackupJob_605290(path: JsonNode; query: JsonNode;
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
  var valid_605292 = path.getOrDefault("backupJobId")
  valid_605292 = validateParameter(valid_605292, JString, required = true,
                                 default = nil)
  if valid_605292 != nil:
    section.add "backupJobId", valid_605292
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
  var valid_605293 = header.getOrDefault("X-Amz-Signature")
  valid_605293 = validateParameter(valid_605293, JString, required = false,
                                 default = nil)
  if valid_605293 != nil:
    section.add "X-Amz-Signature", valid_605293
  var valid_605294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605294 = validateParameter(valid_605294, JString, required = false,
                                 default = nil)
  if valid_605294 != nil:
    section.add "X-Amz-Content-Sha256", valid_605294
  var valid_605295 = header.getOrDefault("X-Amz-Date")
  valid_605295 = validateParameter(valid_605295, JString, required = false,
                                 default = nil)
  if valid_605295 != nil:
    section.add "X-Amz-Date", valid_605295
  var valid_605296 = header.getOrDefault("X-Amz-Credential")
  valid_605296 = validateParameter(valid_605296, JString, required = false,
                                 default = nil)
  if valid_605296 != nil:
    section.add "X-Amz-Credential", valid_605296
  var valid_605297 = header.getOrDefault("X-Amz-Security-Token")
  valid_605297 = validateParameter(valid_605297, JString, required = false,
                                 default = nil)
  if valid_605297 != nil:
    section.add "X-Amz-Security-Token", valid_605297
  var valid_605298 = header.getOrDefault("X-Amz-Algorithm")
  valid_605298 = validateParameter(valid_605298, JString, required = false,
                                 default = nil)
  if valid_605298 != nil:
    section.add "X-Amz-Algorithm", valid_605298
  var valid_605299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605299 = validateParameter(valid_605299, JString, required = false,
                                 default = nil)
  if valid_605299 != nil:
    section.add "X-Amz-SignedHeaders", valid_605299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605300: Call_DescribeBackupJob_605289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a backup of a resource.
  ## 
  let valid = call_605300.validator(path, query, header, formData, body)
  let scheme = call_605300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605300.url(scheme.get, call_605300.host, call_605300.base,
                         call_605300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605300, url, valid)

proc call*(call_605301: Call_DescribeBackupJob_605289; backupJobId: string): Recallable =
  ## describeBackupJob
  ## Returns metadata associated with creating a backup of a resource.
  ##   backupJobId: string (required)
  ##              : Uniquely identifies a request to AWS Backup to back up a resource.
  var path_605302 = newJObject()
  add(path_605302, "backupJobId", newJString(backupJobId))
  result = call_605301.call(path_605302, nil, nil, nil, nil)

var describeBackupJob* = Call_DescribeBackupJob_605289(name: "describeBackupJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-jobs/{backupJobId}", validator: validate_DescribeBackupJob_605290,
    base: "/", url: url_DescribeBackupJob_605291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCopyJob_605317 = ref object of OpenApiRestCall_604389
proc url_DescribeCopyJob_605319(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCopyJob_605318(path: JsonNode; query: JsonNode;
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
  var valid_605320 = path.getOrDefault("copyJobId")
  valid_605320 = validateParameter(valid_605320, JString, required = true,
                                 default = nil)
  if valid_605320 != nil:
    section.add "copyJobId", valid_605320
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
  var valid_605321 = header.getOrDefault("X-Amz-Signature")
  valid_605321 = validateParameter(valid_605321, JString, required = false,
                                 default = nil)
  if valid_605321 != nil:
    section.add "X-Amz-Signature", valid_605321
  var valid_605322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605322 = validateParameter(valid_605322, JString, required = false,
                                 default = nil)
  if valid_605322 != nil:
    section.add "X-Amz-Content-Sha256", valid_605322
  var valid_605323 = header.getOrDefault("X-Amz-Date")
  valid_605323 = validateParameter(valid_605323, JString, required = false,
                                 default = nil)
  if valid_605323 != nil:
    section.add "X-Amz-Date", valid_605323
  var valid_605324 = header.getOrDefault("X-Amz-Credential")
  valid_605324 = validateParameter(valid_605324, JString, required = false,
                                 default = nil)
  if valid_605324 != nil:
    section.add "X-Amz-Credential", valid_605324
  var valid_605325 = header.getOrDefault("X-Amz-Security-Token")
  valid_605325 = validateParameter(valid_605325, JString, required = false,
                                 default = nil)
  if valid_605325 != nil:
    section.add "X-Amz-Security-Token", valid_605325
  var valid_605326 = header.getOrDefault("X-Amz-Algorithm")
  valid_605326 = validateParameter(valid_605326, JString, required = false,
                                 default = nil)
  if valid_605326 != nil:
    section.add "X-Amz-Algorithm", valid_605326
  var valid_605327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605327 = validateParameter(valid_605327, JString, required = false,
                                 default = nil)
  if valid_605327 != nil:
    section.add "X-Amz-SignedHeaders", valid_605327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605328: Call_DescribeCopyJob_605317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with creating a copy of a resource.
  ## 
  let valid = call_605328.validator(path, query, header, formData, body)
  let scheme = call_605328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605328.url(scheme.get, call_605328.host, call_605328.base,
                         call_605328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605328, url, valid)

proc call*(call_605329: Call_DescribeCopyJob_605317; copyJobId: string): Recallable =
  ## describeCopyJob
  ## Returns metadata associated with creating a copy of a resource.
  ##   copyJobId: string (required)
  ##            : Uniquely identifies a request to AWS Backup to copy a resource.
  var path_605330 = newJObject()
  add(path_605330, "copyJobId", newJString(copyJobId))
  result = call_605329.call(path_605330, nil, nil, nil, nil)

var describeCopyJob* = Call_DescribeCopyJob_605317(name: "describeCopyJob",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/copy-jobs/{copyJobId}", validator: validate_DescribeCopyJob_605318,
    base: "/", url: url_DescribeCopyJob_605319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProtectedResource_605331 = ref object of OpenApiRestCall_604389
proc url_DescribeProtectedResource_605333(protocol: Scheme; host: string;
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

proc validate_DescribeProtectedResource_605332(path: JsonNode; query: JsonNode;
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
  var valid_605334 = path.getOrDefault("resourceArn")
  valid_605334 = validateParameter(valid_605334, JString, required = true,
                                 default = nil)
  if valid_605334 != nil:
    section.add "resourceArn", valid_605334
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
  var valid_605335 = header.getOrDefault("X-Amz-Signature")
  valid_605335 = validateParameter(valid_605335, JString, required = false,
                                 default = nil)
  if valid_605335 != nil:
    section.add "X-Amz-Signature", valid_605335
  var valid_605336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605336 = validateParameter(valid_605336, JString, required = false,
                                 default = nil)
  if valid_605336 != nil:
    section.add "X-Amz-Content-Sha256", valid_605336
  var valid_605337 = header.getOrDefault("X-Amz-Date")
  valid_605337 = validateParameter(valid_605337, JString, required = false,
                                 default = nil)
  if valid_605337 != nil:
    section.add "X-Amz-Date", valid_605337
  var valid_605338 = header.getOrDefault("X-Amz-Credential")
  valid_605338 = validateParameter(valid_605338, JString, required = false,
                                 default = nil)
  if valid_605338 != nil:
    section.add "X-Amz-Credential", valid_605338
  var valid_605339 = header.getOrDefault("X-Amz-Security-Token")
  valid_605339 = validateParameter(valid_605339, JString, required = false,
                                 default = nil)
  if valid_605339 != nil:
    section.add "X-Amz-Security-Token", valid_605339
  var valid_605340 = header.getOrDefault("X-Amz-Algorithm")
  valid_605340 = validateParameter(valid_605340, JString, required = false,
                                 default = nil)
  if valid_605340 != nil:
    section.add "X-Amz-Algorithm", valid_605340
  var valid_605341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605341 = validateParameter(valid_605341, JString, required = false,
                                 default = nil)
  if valid_605341 != nil:
    section.add "X-Amz-SignedHeaders", valid_605341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605342: Call_DescribeProtectedResource_605331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ## 
  let valid = call_605342.validator(path, query, header, formData, body)
  let scheme = call_605342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605342.url(scheme.get, call_605342.host, call_605342.base,
                         call_605342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605342, url, valid)

proc call*(call_605343: Call_DescribeProtectedResource_605331; resourceArn: string): Recallable =
  ## describeProtectedResource
  ## Returns information about a saved resource, including the last time it was backed-up, its Amazon Resource Name (ARN), and the AWS service type of the saved resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies a resource. The format of the ARN depends on the resource type.
  var path_605344 = newJObject()
  add(path_605344, "resourceArn", newJString(resourceArn))
  result = call_605343.call(path_605344, nil, nil, nil, nil)

var describeProtectedResource* = Call_DescribeProtectedResource_605331(
    name: "describeProtectedResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/{resourceArn}",
    validator: validate_DescribeProtectedResource_605332, base: "/",
    url: url_DescribeProtectedResource_605333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRestoreJob_605345 = ref object of OpenApiRestCall_604389
proc url_DescribeRestoreJob_605347(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRestoreJob_605346(path: JsonNode; query: JsonNode;
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
  var valid_605348 = path.getOrDefault("restoreJobId")
  valid_605348 = validateParameter(valid_605348, JString, required = true,
                                 default = nil)
  if valid_605348 != nil:
    section.add "restoreJobId", valid_605348
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
  var valid_605349 = header.getOrDefault("X-Amz-Signature")
  valid_605349 = validateParameter(valid_605349, JString, required = false,
                                 default = nil)
  if valid_605349 != nil:
    section.add "X-Amz-Signature", valid_605349
  var valid_605350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605350 = validateParameter(valid_605350, JString, required = false,
                                 default = nil)
  if valid_605350 != nil:
    section.add "X-Amz-Content-Sha256", valid_605350
  var valid_605351 = header.getOrDefault("X-Amz-Date")
  valid_605351 = validateParameter(valid_605351, JString, required = false,
                                 default = nil)
  if valid_605351 != nil:
    section.add "X-Amz-Date", valid_605351
  var valid_605352 = header.getOrDefault("X-Amz-Credential")
  valid_605352 = validateParameter(valid_605352, JString, required = false,
                                 default = nil)
  if valid_605352 != nil:
    section.add "X-Amz-Credential", valid_605352
  var valid_605353 = header.getOrDefault("X-Amz-Security-Token")
  valid_605353 = validateParameter(valid_605353, JString, required = false,
                                 default = nil)
  if valid_605353 != nil:
    section.add "X-Amz-Security-Token", valid_605353
  var valid_605354 = header.getOrDefault("X-Amz-Algorithm")
  valid_605354 = validateParameter(valid_605354, JString, required = false,
                                 default = nil)
  if valid_605354 != nil:
    section.add "X-Amz-Algorithm", valid_605354
  var valid_605355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605355 = validateParameter(valid_605355, JString, required = false,
                                 default = nil)
  if valid_605355 != nil:
    section.add "X-Amz-SignedHeaders", valid_605355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605356: Call_DescribeRestoreJob_605345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ## 
  let valid = call_605356.validator(path, query, header, formData, body)
  let scheme = call_605356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605356.url(scheme.get, call_605356.host, call_605356.base,
                         call_605356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605356, url, valid)

proc call*(call_605357: Call_DescribeRestoreJob_605345; restoreJobId: string): Recallable =
  ## describeRestoreJob
  ## Returns metadata associated with a restore job that is specified by a job ID.
  ##   restoreJobId: string (required)
  ##               : Uniquely identifies the job that restores a recovery point.
  var path_605358 = newJObject()
  add(path_605358, "restoreJobId", newJString(restoreJobId))
  result = call_605357.call(path_605358, nil, nil, nil, nil)

var describeRestoreJob* = Call_DescribeRestoreJob_605345(
    name: "describeRestoreJob", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/restore-jobs/{restoreJobId}",
    validator: validate_DescribeRestoreJob_605346, base: "/",
    url: url_DescribeRestoreJob_605347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportBackupPlanTemplate_605359 = ref object of OpenApiRestCall_604389
proc url_ExportBackupPlanTemplate_605361(protocol: Scheme; host: string;
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

proc validate_ExportBackupPlanTemplate_605360(path: JsonNode; query: JsonNode;
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
  var valid_605362 = path.getOrDefault("backupPlanId")
  valid_605362 = validateParameter(valid_605362, JString, required = true,
                                 default = nil)
  if valid_605362 != nil:
    section.add "backupPlanId", valid_605362
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
  var valid_605363 = header.getOrDefault("X-Amz-Signature")
  valid_605363 = validateParameter(valid_605363, JString, required = false,
                                 default = nil)
  if valid_605363 != nil:
    section.add "X-Amz-Signature", valid_605363
  var valid_605364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605364 = validateParameter(valid_605364, JString, required = false,
                                 default = nil)
  if valid_605364 != nil:
    section.add "X-Amz-Content-Sha256", valid_605364
  var valid_605365 = header.getOrDefault("X-Amz-Date")
  valid_605365 = validateParameter(valid_605365, JString, required = false,
                                 default = nil)
  if valid_605365 != nil:
    section.add "X-Amz-Date", valid_605365
  var valid_605366 = header.getOrDefault("X-Amz-Credential")
  valid_605366 = validateParameter(valid_605366, JString, required = false,
                                 default = nil)
  if valid_605366 != nil:
    section.add "X-Amz-Credential", valid_605366
  var valid_605367 = header.getOrDefault("X-Amz-Security-Token")
  valid_605367 = validateParameter(valid_605367, JString, required = false,
                                 default = nil)
  if valid_605367 != nil:
    section.add "X-Amz-Security-Token", valid_605367
  var valid_605368 = header.getOrDefault("X-Amz-Algorithm")
  valid_605368 = validateParameter(valid_605368, JString, required = false,
                                 default = nil)
  if valid_605368 != nil:
    section.add "X-Amz-Algorithm", valid_605368
  var valid_605369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605369 = validateParameter(valid_605369, JString, required = false,
                                 default = nil)
  if valid_605369 != nil:
    section.add "X-Amz-SignedHeaders", valid_605369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605370: Call_ExportBackupPlanTemplate_605359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ## 
  let valid = call_605370.validator(path, query, header, formData, body)
  let scheme = call_605370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605370.url(scheme.get, call_605370.host, call_605370.base,
                         call_605370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605370, url, valid)

proc call*(call_605371: Call_ExportBackupPlanTemplate_605359; backupPlanId: string): Recallable =
  ## exportBackupPlanTemplate
  ## Returns the backup plan that is specified by the plan ID as a backup template.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_605372 = newJObject()
  add(path_605372, "backupPlanId", newJString(backupPlanId))
  result = call_605371.call(path_605372, nil, nil, nil, nil)

var exportBackupPlanTemplate* = Call_ExportBackupPlanTemplate_605359(
    name: "exportBackupPlanTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/toTemplate/",
    validator: validate_ExportBackupPlanTemplate_605360, base: "/",
    url: url_ExportBackupPlanTemplate_605361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlan_605373 = ref object of OpenApiRestCall_604389
proc url_GetBackupPlan_605375(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupPlan_605374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605376 = path.getOrDefault("backupPlanId")
  valid_605376 = validateParameter(valid_605376, JString, required = true,
                                 default = nil)
  if valid_605376 != nil:
    section.add "backupPlanId", valid_605376
  result.add "path", section
  ## parameters in `query` object:
  ##   versionId: JString
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  section = newJObject()
  var valid_605377 = query.getOrDefault("versionId")
  valid_605377 = validateParameter(valid_605377, JString, required = false,
                                 default = nil)
  if valid_605377 != nil:
    section.add "versionId", valid_605377
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
  var valid_605378 = header.getOrDefault("X-Amz-Signature")
  valid_605378 = validateParameter(valid_605378, JString, required = false,
                                 default = nil)
  if valid_605378 != nil:
    section.add "X-Amz-Signature", valid_605378
  var valid_605379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605379 = validateParameter(valid_605379, JString, required = false,
                                 default = nil)
  if valid_605379 != nil:
    section.add "X-Amz-Content-Sha256", valid_605379
  var valid_605380 = header.getOrDefault("X-Amz-Date")
  valid_605380 = validateParameter(valid_605380, JString, required = false,
                                 default = nil)
  if valid_605380 != nil:
    section.add "X-Amz-Date", valid_605380
  var valid_605381 = header.getOrDefault("X-Amz-Credential")
  valid_605381 = validateParameter(valid_605381, JString, required = false,
                                 default = nil)
  if valid_605381 != nil:
    section.add "X-Amz-Credential", valid_605381
  var valid_605382 = header.getOrDefault("X-Amz-Security-Token")
  valid_605382 = validateParameter(valid_605382, JString, required = false,
                                 default = nil)
  if valid_605382 != nil:
    section.add "X-Amz-Security-Token", valid_605382
  var valid_605383 = header.getOrDefault("X-Amz-Algorithm")
  valid_605383 = validateParameter(valid_605383, JString, required = false,
                                 default = nil)
  if valid_605383 != nil:
    section.add "X-Amz-Algorithm", valid_605383
  var valid_605384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605384 = validateParameter(valid_605384, JString, required = false,
                                 default = nil)
  if valid_605384 != nil:
    section.add "X-Amz-SignedHeaders", valid_605384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605385: Call_GetBackupPlan_605373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ## 
  let valid = call_605385.validator(path, query, header, formData, body)
  let scheme = call_605385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605385.url(scheme.get, call_605385.host, call_605385.base,
                         call_605385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605385, url, valid)

proc call*(call_605386: Call_GetBackupPlan_605373; backupPlanId: string;
          versionId: string = ""): Recallable =
  ## getBackupPlan
  ## Returns the body of a backup plan in JSON format, in addition to plan metadata.
  ##   versionId: string
  ##            : Unique, randomly generated, Unicode, UTF-8 encoded strings that are at most 1,024 bytes long. Version IDs cannot be edited.
  ##   backupPlanId: string (required)
  ##               : Uniquely identifies a backup plan.
  var path_605387 = newJObject()
  var query_605388 = newJObject()
  add(query_605388, "versionId", newJString(versionId))
  add(path_605387, "backupPlanId", newJString(backupPlanId))
  result = call_605386.call(path_605387, query_605388, nil, nil, nil)

var getBackupPlan* = Call_GetBackupPlan_605373(name: "getBackupPlan",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup/plans/{backupPlanId}/", validator: validate_GetBackupPlan_605374,
    base: "/", url: url_GetBackupPlan_605375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromJSON_605389 = ref object of OpenApiRestCall_604389
proc url_GetBackupPlanFromJSON_605391(protocol: Scheme; host: string; base: string;
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

proc validate_GetBackupPlanFromJSON_605390(path: JsonNode; query: JsonNode;
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
  var valid_605392 = header.getOrDefault("X-Amz-Signature")
  valid_605392 = validateParameter(valid_605392, JString, required = false,
                                 default = nil)
  if valid_605392 != nil:
    section.add "X-Amz-Signature", valid_605392
  var valid_605393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605393 = validateParameter(valid_605393, JString, required = false,
                                 default = nil)
  if valid_605393 != nil:
    section.add "X-Amz-Content-Sha256", valid_605393
  var valid_605394 = header.getOrDefault("X-Amz-Date")
  valid_605394 = validateParameter(valid_605394, JString, required = false,
                                 default = nil)
  if valid_605394 != nil:
    section.add "X-Amz-Date", valid_605394
  var valid_605395 = header.getOrDefault("X-Amz-Credential")
  valid_605395 = validateParameter(valid_605395, JString, required = false,
                                 default = nil)
  if valid_605395 != nil:
    section.add "X-Amz-Credential", valid_605395
  var valid_605396 = header.getOrDefault("X-Amz-Security-Token")
  valid_605396 = validateParameter(valid_605396, JString, required = false,
                                 default = nil)
  if valid_605396 != nil:
    section.add "X-Amz-Security-Token", valid_605396
  var valid_605397 = header.getOrDefault("X-Amz-Algorithm")
  valid_605397 = validateParameter(valid_605397, JString, required = false,
                                 default = nil)
  if valid_605397 != nil:
    section.add "X-Amz-Algorithm", valid_605397
  var valid_605398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605398 = validateParameter(valid_605398, JString, required = false,
                                 default = nil)
  if valid_605398 != nil:
    section.add "X-Amz-SignedHeaders", valid_605398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605400: Call_GetBackupPlanFromJSON_605389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a valid JSON document specifying a backup plan or an error.
  ## 
  let valid = call_605400.validator(path, query, header, formData, body)
  let scheme = call_605400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605400.url(scheme.get, call_605400.host, call_605400.base,
                         call_605400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605400, url, valid)

proc call*(call_605401: Call_GetBackupPlanFromJSON_605389; body: JsonNode): Recallable =
  ## getBackupPlanFromJSON
  ## Returns a valid JSON document specifying a backup plan or an error.
  ##   body: JObject (required)
  var body_605402 = newJObject()
  if body != nil:
    body_605402 = body
  result = call_605401.call(nil, nil, nil, nil, body_605402)

var getBackupPlanFromJSON* = Call_GetBackupPlanFromJSON_605389(
    name: "getBackupPlanFromJSON", meth: HttpMethod.HttpPost,
    host: "backup.amazonaws.com", route: "/backup/template/json/toPlan",
    validator: validate_GetBackupPlanFromJSON_605390, base: "/",
    url: url_GetBackupPlanFromJSON_605391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBackupPlanFromTemplate_605403 = ref object of OpenApiRestCall_604389
proc url_GetBackupPlanFromTemplate_605405(protocol: Scheme; host: string;
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

proc validate_GetBackupPlanFromTemplate_605404(path: JsonNode; query: JsonNode;
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
  var valid_605406 = path.getOrDefault("templateId")
  valid_605406 = validateParameter(valid_605406, JString, required = true,
                                 default = nil)
  if valid_605406 != nil:
    section.add "templateId", valid_605406
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
  var valid_605407 = header.getOrDefault("X-Amz-Signature")
  valid_605407 = validateParameter(valid_605407, JString, required = false,
                                 default = nil)
  if valid_605407 != nil:
    section.add "X-Amz-Signature", valid_605407
  var valid_605408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605408 = validateParameter(valid_605408, JString, required = false,
                                 default = nil)
  if valid_605408 != nil:
    section.add "X-Amz-Content-Sha256", valid_605408
  var valid_605409 = header.getOrDefault("X-Amz-Date")
  valid_605409 = validateParameter(valid_605409, JString, required = false,
                                 default = nil)
  if valid_605409 != nil:
    section.add "X-Amz-Date", valid_605409
  var valid_605410 = header.getOrDefault("X-Amz-Credential")
  valid_605410 = validateParameter(valid_605410, JString, required = false,
                                 default = nil)
  if valid_605410 != nil:
    section.add "X-Amz-Credential", valid_605410
  var valid_605411 = header.getOrDefault("X-Amz-Security-Token")
  valid_605411 = validateParameter(valid_605411, JString, required = false,
                                 default = nil)
  if valid_605411 != nil:
    section.add "X-Amz-Security-Token", valid_605411
  var valid_605412 = header.getOrDefault("X-Amz-Algorithm")
  valid_605412 = validateParameter(valid_605412, JString, required = false,
                                 default = nil)
  if valid_605412 != nil:
    section.add "X-Amz-Algorithm", valid_605412
  var valid_605413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605413 = validateParameter(valid_605413, JString, required = false,
                                 default = nil)
  if valid_605413 != nil:
    section.add "X-Amz-SignedHeaders", valid_605413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605414: Call_GetBackupPlanFromTemplate_605403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ## 
  let valid = call_605414.validator(path, query, header, formData, body)
  let scheme = call_605414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605414.url(scheme.get, call_605414.host, call_605414.base,
                         call_605414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605414, url, valid)

proc call*(call_605415: Call_GetBackupPlanFromTemplate_605403; templateId: string): Recallable =
  ## getBackupPlanFromTemplate
  ## Returns the template specified by its <code>templateId</code> as a backup plan.
  ##   templateId: string (required)
  ##             : Uniquely identifies a stored backup plan template.
  var path_605416 = newJObject()
  add(path_605416, "templateId", newJString(templateId))
  result = call_605415.call(path_605416, nil, nil, nil, nil)

var getBackupPlanFromTemplate* = Call_GetBackupPlanFromTemplate_605403(
    name: "getBackupPlanFromTemplate", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup/template/plans/{templateId}/toPlan",
    validator: validate_GetBackupPlanFromTemplate_605404, base: "/",
    url: url_GetBackupPlanFromTemplate_605405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRecoveryPointRestoreMetadata_605417 = ref object of OpenApiRestCall_604389
proc url_GetRecoveryPointRestoreMetadata_605419(protocol: Scheme; host: string;
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

proc validate_GetRecoveryPointRestoreMetadata_605418(path: JsonNode;
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
  var valid_605420 = path.getOrDefault("backupVaultName")
  valid_605420 = validateParameter(valid_605420, JString, required = true,
                                 default = nil)
  if valid_605420 != nil:
    section.add "backupVaultName", valid_605420
  var valid_605421 = path.getOrDefault("recoveryPointArn")
  valid_605421 = validateParameter(valid_605421, JString, required = true,
                                 default = nil)
  if valid_605421 != nil:
    section.add "recoveryPointArn", valid_605421
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
  var valid_605422 = header.getOrDefault("X-Amz-Signature")
  valid_605422 = validateParameter(valid_605422, JString, required = false,
                                 default = nil)
  if valid_605422 != nil:
    section.add "X-Amz-Signature", valid_605422
  var valid_605423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605423 = validateParameter(valid_605423, JString, required = false,
                                 default = nil)
  if valid_605423 != nil:
    section.add "X-Amz-Content-Sha256", valid_605423
  var valid_605424 = header.getOrDefault("X-Amz-Date")
  valid_605424 = validateParameter(valid_605424, JString, required = false,
                                 default = nil)
  if valid_605424 != nil:
    section.add "X-Amz-Date", valid_605424
  var valid_605425 = header.getOrDefault("X-Amz-Credential")
  valid_605425 = validateParameter(valid_605425, JString, required = false,
                                 default = nil)
  if valid_605425 != nil:
    section.add "X-Amz-Credential", valid_605425
  var valid_605426 = header.getOrDefault("X-Amz-Security-Token")
  valid_605426 = validateParameter(valid_605426, JString, required = false,
                                 default = nil)
  if valid_605426 != nil:
    section.add "X-Amz-Security-Token", valid_605426
  var valid_605427 = header.getOrDefault("X-Amz-Algorithm")
  valid_605427 = validateParameter(valid_605427, JString, required = false,
                                 default = nil)
  if valid_605427 != nil:
    section.add "X-Amz-Algorithm", valid_605427
  var valid_605428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605428 = validateParameter(valid_605428, JString, required = false,
                                 default = nil)
  if valid_605428 != nil:
    section.add "X-Amz-SignedHeaders", valid_605428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605429: Call_GetRecoveryPointRestoreMetadata_605417;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ## 
  let valid = call_605429.validator(path, query, header, formData, body)
  let scheme = call_605429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605429.url(scheme.get, call_605429.host, call_605429.base,
                         call_605429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605429, url, valid)

proc call*(call_605430: Call_GetRecoveryPointRestoreMetadata_605417;
          backupVaultName: string; recoveryPointArn: string): Recallable =
  ## getRecoveryPointRestoreMetadata
  ## Returns a set of metadata key-value pairs that were used to create the backup.
  ##   backupVaultName: string (required)
  ##                  : The name of a logical container where backups are stored. Backup vaults are identified by names that are unique to the account used to create them and the AWS Region where they are created. They consist of lowercase letters, numbers, and hyphens.
  ##   recoveryPointArn: string (required)
  ##                   : An Amazon Resource Name (ARN) that uniquely identifies a recovery point; for example, 
  ## <code>arn:aws:backup:us-east-1:123456789012:recovery-point:1EB3B5E7-9EB0-435A-A80B-108B488B0D45</code>.
  var path_605431 = newJObject()
  add(path_605431, "backupVaultName", newJString(backupVaultName))
  add(path_605431, "recoveryPointArn", newJString(recoveryPointArn))
  result = call_605430.call(path_605431, nil, nil, nil, nil)

var getRecoveryPointRestoreMetadata* = Call_GetRecoveryPointRestoreMetadata_605417(
    name: "getRecoveryPointRestoreMetadata", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup-vaults/{backupVaultName}/recovery-points/{recoveryPointArn}/restore-metadata",
    validator: validate_GetRecoveryPointRestoreMetadata_605418, base: "/",
    url: url_GetRecoveryPointRestoreMetadata_605419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSupportedResourceTypes_605432 = ref object of OpenApiRestCall_604389
proc url_GetSupportedResourceTypes_605434(protocol: Scheme; host: string;
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

proc validate_GetSupportedResourceTypes_605433(path: JsonNode; query: JsonNode;
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
  var valid_605435 = header.getOrDefault("X-Amz-Signature")
  valid_605435 = validateParameter(valid_605435, JString, required = false,
                                 default = nil)
  if valid_605435 != nil:
    section.add "X-Amz-Signature", valid_605435
  var valid_605436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605436 = validateParameter(valid_605436, JString, required = false,
                                 default = nil)
  if valid_605436 != nil:
    section.add "X-Amz-Content-Sha256", valid_605436
  var valid_605437 = header.getOrDefault("X-Amz-Date")
  valid_605437 = validateParameter(valid_605437, JString, required = false,
                                 default = nil)
  if valid_605437 != nil:
    section.add "X-Amz-Date", valid_605437
  var valid_605438 = header.getOrDefault("X-Amz-Credential")
  valid_605438 = validateParameter(valid_605438, JString, required = false,
                                 default = nil)
  if valid_605438 != nil:
    section.add "X-Amz-Credential", valid_605438
  var valid_605439 = header.getOrDefault("X-Amz-Security-Token")
  valid_605439 = validateParameter(valid_605439, JString, required = false,
                                 default = nil)
  if valid_605439 != nil:
    section.add "X-Amz-Security-Token", valid_605439
  var valid_605440 = header.getOrDefault("X-Amz-Algorithm")
  valid_605440 = validateParameter(valid_605440, JString, required = false,
                                 default = nil)
  if valid_605440 != nil:
    section.add "X-Amz-Algorithm", valid_605440
  var valid_605441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605441 = validateParameter(valid_605441, JString, required = false,
                                 default = nil)
  if valid_605441 != nil:
    section.add "X-Amz-SignedHeaders", valid_605441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605442: Call_GetSupportedResourceTypes_605432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the AWS resource types supported by AWS Backup.
  ## 
  let valid = call_605442.validator(path, query, header, formData, body)
  let scheme = call_605442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605442.url(scheme.get, call_605442.host, call_605442.base,
                         call_605442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605442, url, valid)

proc call*(call_605443: Call_GetSupportedResourceTypes_605432): Recallable =
  ## getSupportedResourceTypes
  ## Returns the AWS resource types supported by AWS Backup.
  result = call_605443.call(nil, nil, nil, nil, nil)

var getSupportedResourceTypes* = Call_GetSupportedResourceTypes_605432(
    name: "getSupportedResourceTypes", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/supported-resource-types",
    validator: validate_GetSupportedResourceTypes_605433, base: "/",
    url: url_GetSupportedResourceTypes_605434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupJobs_605444 = ref object of OpenApiRestCall_604389
proc url_ListBackupJobs_605446(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupJobs_605445(path: JsonNode; query: JsonNode;
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
  var valid_605447 = query.getOrDefault("nextToken")
  valid_605447 = validateParameter(valid_605447, JString, required = false,
                                 default = nil)
  if valid_605447 != nil:
    section.add "nextToken", valid_605447
  var valid_605448 = query.getOrDefault("backupVaultName")
  valid_605448 = validateParameter(valid_605448, JString, required = false,
                                 default = nil)
  if valid_605448 != nil:
    section.add "backupVaultName", valid_605448
  var valid_605449 = query.getOrDefault("MaxResults")
  valid_605449 = validateParameter(valid_605449, JString, required = false,
                                 default = nil)
  if valid_605449 != nil:
    section.add "MaxResults", valid_605449
  var valid_605463 = query.getOrDefault("state")
  valid_605463 = validateParameter(valid_605463, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_605463 != nil:
    section.add "state", valid_605463
  var valid_605464 = query.getOrDefault("NextToken")
  valid_605464 = validateParameter(valid_605464, JString, required = false,
                                 default = nil)
  if valid_605464 != nil:
    section.add "NextToken", valid_605464
  var valid_605465 = query.getOrDefault("createdAfter")
  valid_605465 = validateParameter(valid_605465, JString, required = false,
                                 default = nil)
  if valid_605465 != nil:
    section.add "createdAfter", valid_605465
  var valid_605466 = query.getOrDefault("resourceType")
  valid_605466 = validateParameter(valid_605466, JString, required = false,
                                 default = nil)
  if valid_605466 != nil:
    section.add "resourceType", valid_605466
  var valid_605467 = query.getOrDefault("createdBefore")
  valid_605467 = validateParameter(valid_605467, JString, required = false,
                                 default = nil)
  if valid_605467 != nil:
    section.add "createdBefore", valid_605467
  var valid_605468 = query.getOrDefault("resourceArn")
  valid_605468 = validateParameter(valid_605468, JString, required = false,
                                 default = nil)
  if valid_605468 != nil:
    section.add "resourceArn", valid_605468
  var valid_605469 = query.getOrDefault("maxResults")
  valid_605469 = validateParameter(valid_605469, JInt, required = false, default = nil)
  if valid_605469 != nil:
    section.add "maxResults", valid_605469
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
  var valid_605470 = header.getOrDefault("X-Amz-Signature")
  valid_605470 = validateParameter(valid_605470, JString, required = false,
                                 default = nil)
  if valid_605470 != nil:
    section.add "X-Amz-Signature", valid_605470
  var valid_605471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605471 = validateParameter(valid_605471, JString, required = false,
                                 default = nil)
  if valid_605471 != nil:
    section.add "X-Amz-Content-Sha256", valid_605471
  var valid_605472 = header.getOrDefault("X-Amz-Date")
  valid_605472 = validateParameter(valid_605472, JString, required = false,
                                 default = nil)
  if valid_605472 != nil:
    section.add "X-Amz-Date", valid_605472
  var valid_605473 = header.getOrDefault("X-Amz-Credential")
  valid_605473 = validateParameter(valid_605473, JString, required = false,
                                 default = nil)
  if valid_605473 != nil:
    section.add "X-Amz-Credential", valid_605473
  var valid_605474 = header.getOrDefault("X-Amz-Security-Token")
  valid_605474 = validateParameter(valid_605474, JString, required = false,
                                 default = nil)
  if valid_605474 != nil:
    section.add "X-Amz-Security-Token", valid_605474
  var valid_605475 = header.getOrDefault("X-Amz-Algorithm")
  valid_605475 = validateParameter(valid_605475, JString, required = false,
                                 default = nil)
  if valid_605475 != nil:
    section.add "X-Amz-Algorithm", valid_605475
  var valid_605476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605476 = validateParameter(valid_605476, JString, required = false,
                                 default = nil)
  if valid_605476 != nil:
    section.add "X-Amz-SignedHeaders", valid_605476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605477: Call_ListBackupJobs_605444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your backup jobs.
  ## 
  let valid = call_605477.validator(path, query, header, formData, body)
  let scheme = call_605477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605477.url(scheme.get, call_605477.host, call_605477.base,
                         call_605477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605477, url, valid)

proc call*(call_605478: Call_ListBackupJobs_605444; nextToken: string = "";
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
  var query_605479 = newJObject()
  add(query_605479, "nextToken", newJString(nextToken))
  add(query_605479, "backupVaultName", newJString(backupVaultName))
  add(query_605479, "MaxResults", newJString(MaxResults))
  add(query_605479, "state", newJString(state))
  add(query_605479, "NextToken", newJString(NextToken))
  add(query_605479, "createdAfter", newJString(createdAfter))
  add(query_605479, "resourceType", newJString(resourceType))
  add(query_605479, "createdBefore", newJString(createdBefore))
  add(query_605479, "resourceArn", newJString(resourceArn))
  add(query_605479, "maxResults", newJInt(maxResults))
  result = call_605478.call(nil, query_605479, nil, nil, nil)

var listBackupJobs* = Call_ListBackupJobs_605444(name: "listBackupJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/backup-jobs/",
    validator: validate_ListBackupJobs_605445, base: "/", url: url_ListBackupJobs_605446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanTemplates_605480 = ref object of OpenApiRestCall_604389
proc url_ListBackupPlanTemplates_605482(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlanTemplates_605481(path: JsonNode; query: JsonNode;
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
  var valid_605483 = query.getOrDefault("nextToken")
  valid_605483 = validateParameter(valid_605483, JString, required = false,
                                 default = nil)
  if valid_605483 != nil:
    section.add "nextToken", valid_605483
  var valid_605484 = query.getOrDefault("MaxResults")
  valid_605484 = validateParameter(valid_605484, JString, required = false,
                                 default = nil)
  if valid_605484 != nil:
    section.add "MaxResults", valid_605484
  var valid_605485 = query.getOrDefault("NextToken")
  valid_605485 = validateParameter(valid_605485, JString, required = false,
                                 default = nil)
  if valid_605485 != nil:
    section.add "NextToken", valid_605485
  var valid_605486 = query.getOrDefault("maxResults")
  valid_605486 = validateParameter(valid_605486, JInt, required = false, default = nil)
  if valid_605486 != nil:
    section.add "maxResults", valid_605486
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
  var valid_605487 = header.getOrDefault("X-Amz-Signature")
  valid_605487 = validateParameter(valid_605487, JString, required = false,
                                 default = nil)
  if valid_605487 != nil:
    section.add "X-Amz-Signature", valid_605487
  var valid_605488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605488 = validateParameter(valid_605488, JString, required = false,
                                 default = nil)
  if valid_605488 != nil:
    section.add "X-Amz-Content-Sha256", valid_605488
  var valid_605489 = header.getOrDefault("X-Amz-Date")
  valid_605489 = validateParameter(valid_605489, JString, required = false,
                                 default = nil)
  if valid_605489 != nil:
    section.add "X-Amz-Date", valid_605489
  var valid_605490 = header.getOrDefault("X-Amz-Credential")
  valid_605490 = validateParameter(valid_605490, JString, required = false,
                                 default = nil)
  if valid_605490 != nil:
    section.add "X-Amz-Credential", valid_605490
  var valid_605491 = header.getOrDefault("X-Amz-Security-Token")
  valid_605491 = validateParameter(valid_605491, JString, required = false,
                                 default = nil)
  if valid_605491 != nil:
    section.add "X-Amz-Security-Token", valid_605491
  var valid_605492 = header.getOrDefault("X-Amz-Algorithm")
  valid_605492 = validateParameter(valid_605492, JString, required = false,
                                 default = nil)
  if valid_605492 != nil:
    section.add "X-Amz-Algorithm", valid_605492
  var valid_605493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605493 = validateParameter(valid_605493, JString, required = false,
                                 default = nil)
  if valid_605493 != nil:
    section.add "X-Amz-SignedHeaders", valid_605493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605494: Call_ListBackupPlanTemplates_605480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata of your saved backup plan templates, including the template ID, name, and the creation and deletion dates.
  ## 
  let valid = call_605494.validator(path, query, header, formData, body)
  let scheme = call_605494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605494.url(scheme.get, call_605494.host, call_605494.base,
                         call_605494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605494, url, valid)

proc call*(call_605495: Call_ListBackupPlanTemplates_605480;
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
  var query_605496 = newJObject()
  add(query_605496, "nextToken", newJString(nextToken))
  add(query_605496, "MaxResults", newJString(MaxResults))
  add(query_605496, "NextToken", newJString(NextToken))
  add(query_605496, "maxResults", newJInt(maxResults))
  result = call_605495.call(nil, query_605496, nil, nil, nil)

var listBackupPlanTemplates* = Call_ListBackupPlanTemplates_605480(
    name: "listBackupPlanTemplates", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/template/plans",
    validator: validate_ListBackupPlanTemplates_605481, base: "/",
    url: url_ListBackupPlanTemplates_605482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupPlanVersions_605497 = ref object of OpenApiRestCall_604389
proc url_ListBackupPlanVersions_605499(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupPlanVersions_605498(path: JsonNode; query: JsonNode;
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
  var valid_605500 = path.getOrDefault("backupPlanId")
  valid_605500 = validateParameter(valid_605500, JString, required = true,
                                 default = nil)
  if valid_605500 != nil:
    section.add "backupPlanId", valid_605500
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
  var valid_605501 = query.getOrDefault("nextToken")
  valid_605501 = validateParameter(valid_605501, JString, required = false,
                                 default = nil)
  if valid_605501 != nil:
    section.add "nextToken", valid_605501
  var valid_605502 = query.getOrDefault("MaxResults")
  valid_605502 = validateParameter(valid_605502, JString, required = false,
                                 default = nil)
  if valid_605502 != nil:
    section.add "MaxResults", valid_605502
  var valid_605503 = query.getOrDefault("NextToken")
  valid_605503 = validateParameter(valid_605503, JString, required = false,
                                 default = nil)
  if valid_605503 != nil:
    section.add "NextToken", valid_605503
  var valid_605504 = query.getOrDefault("maxResults")
  valid_605504 = validateParameter(valid_605504, JInt, required = false, default = nil)
  if valid_605504 != nil:
    section.add "maxResults", valid_605504
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
  var valid_605505 = header.getOrDefault("X-Amz-Signature")
  valid_605505 = validateParameter(valid_605505, JString, required = false,
                                 default = nil)
  if valid_605505 != nil:
    section.add "X-Amz-Signature", valid_605505
  var valid_605506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605506 = validateParameter(valid_605506, JString, required = false,
                                 default = nil)
  if valid_605506 != nil:
    section.add "X-Amz-Content-Sha256", valid_605506
  var valid_605507 = header.getOrDefault("X-Amz-Date")
  valid_605507 = validateParameter(valid_605507, JString, required = false,
                                 default = nil)
  if valid_605507 != nil:
    section.add "X-Amz-Date", valid_605507
  var valid_605508 = header.getOrDefault("X-Amz-Credential")
  valid_605508 = validateParameter(valid_605508, JString, required = false,
                                 default = nil)
  if valid_605508 != nil:
    section.add "X-Amz-Credential", valid_605508
  var valid_605509 = header.getOrDefault("X-Amz-Security-Token")
  valid_605509 = validateParameter(valid_605509, JString, required = false,
                                 default = nil)
  if valid_605509 != nil:
    section.add "X-Amz-Security-Token", valid_605509
  var valid_605510 = header.getOrDefault("X-Amz-Algorithm")
  valid_605510 = validateParameter(valid_605510, JString, required = false,
                                 default = nil)
  if valid_605510 != nil:
    section.add "X-Amz-Algorithm", valid_605510
  var valid_605511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605511 = validateParameter(valid_605511, JString, required = false,
                                 default = nil)
  if valid_605511 != nil:
    section.add "X-Amz-SignedHeaders", valid_605511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605512: Call_ListBackupPlanVersions_605497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns version metadata of your backup plans, including Amazon Resource Names (ARNs), backup plan IDs, creation and deletion dates, plan names, and version IDs.
  ## 
  let valid = call_605512.validator(path, query, header, formData, body)
  let scheme = call_605512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605512.url(scheme.get, call_605512.host, call_605512.base,
                         call_605512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605512, url, valid)

proc call*(call_605513: Call_ListBackupPlanVersions_605497; backupPlanId: string;
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
  var path_605514 = newJObject()
  var query_605515 = newJObject()
  add(query_605515, "nextToken", newJString(nextToken))
  add(query_605515, "MaxResults", newJString(MaxResults))
  add(query_605515, "NextToken", newJString(NextToken))
  add(path_605514, "backupPlanId", newJString(backupPlanId))
  add(query_605515, "maxResults", newJInt(maxResults))
  result = call_605513.call(path_605514, query_605515, nil, nil, nil)

var listBackupPlanVersions* = Call_ListBackupPlanVersions_605497(
    name: "listBackupPlanVersions", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/backup/plans/{backupPlanId}/versions/",
    validator: validate_ListBackupPlanVersions_605498, base: "/",
    url: url_ListBackupPlanVersions_605499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBackupVaults_605516 = ref object of OpenApiRestCall_604389
proc url_ListBackupVaults_605518(protocol: Scheme; host: string; base: string;
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

proc validate_ListBackupVaults_605517(path: JsonNode; query: JsonNode;
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
  var valid_605519 = query.getOrDefault("nextToken")
  valid_605519 = validateParameter(valid_605519, JString, required = false,
                                 default = nil)
  if valid_605519 != nil:
    section.add "nextToken", valid_605519
  var valid_605520 = query.getOrDefault("MaxResults")
  valid_605520 = validateParameter(valid_605520, JString, required = false,
                                 default = nil)
  if valid_605520 != nil:
    section.add "MaxResults", valid_605520
  var valid_605521 = query.getOrDefault("NextToken")
  valid_605521 = validateParameter(valid_605521, JString, required = false,
                                 default = nil)
  if valid_605521 != nil:
    section.add "NextToken", valid_605521
  var valid_605522 = query.getOrDefault("maxResults")
  valid_605522 = validateParameter(valid_605522, JInt, required = false, default = nil)
  if valid_605522 != nil:
    section.add "maxResults", valid_605522
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
  var valid_605523 = header.getOrDefault("X-Amz-Signature")
  valid_605523 = validateParameter(valid_605523, JString, required = false,
                                 default = nil)
  if valid_605523 != nil:
    section.add "X-Amz-Signature", valid_605523
  var valid_605524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605524 = validateParameter(valid_605524, JString, required = false,
                                 default = nil)
  if valid_605524 != nil:
    section.add "X-Amz-Content-Sha256", valid_605524
  var valid_605525 = header.getOrDefault("X-Amz-Date")
  valid_605525 = validateParameter(valid_605525, JString, required = false,
                                 default = nil)
  if valid_605525 != nil:
    section.add "X-Amz-Date", valid_605525
  var valid_605526 = header.getOrDefault("X-Amz-Credential")
  valid_605526 = validateParameter(valid_605526, JString, required = false,
                                 default = nil)
  if valid_605526 != nil:
    section.add "X-Amz-Credential", valid_605526
  var valid_605527 = header.getOrDefault("X-Amz-Security-Token")
  valid_605527 = validateParameter(valid_605527, JString, required = false,
                                 default = nil)
  if valid_605527 != nil:
    section.add "X-Amz-Security-Token", valid_605527
  var valid_605528 = header.getOrDefault("X-Amz-Algorithm")
  valid_605528 = validateParameter(valid_605528, JString, required = false,
                                 default = nil)
  if valid_605528 != nil:
    section.add "X-Amz-Algorithm", valid_605528
  var valid_605529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605529 = validateParameter(valid_605529, JString, required = false,
                                 default = nil)
  if valid_605529 != nil:
    section.add "X-Amz-SignedHeaders", valid_605529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605530: Call_ListBackupVaults_605516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of recovery point storage containers along with information about them.
  ## 
  let valid = call_605530.validator(path, query, header, formData, body)
  let scheme = call_605530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605530.url(scheme.get, call_605530.host, call_605530.base,
                         call_605530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605530, url, valid)

proc call*(call_605531: Call_ListBackupVaults_605516; nextToken: string = "";
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
  var query_605532 = newJObject()
  add(query_605532, "nextToken", newJString(nextToken))
  add(query_605532, "MaxResults", newJString(MaxResults))
  add(query_605532, "NextToken", newJString(NextToken))
  add(query_605532, "maxResults", newJInt(maxResults))
  result = call_605531.call(nil, query_605532, nil, nil, nil)

var listBackupVaults* = Call_ListBackupVaults_605516(name: "listBackupVaults",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com",
    route: "/backup-vaults/", validator: validate_ListBackupVaults_605517,
    base: "/", url: url_ListBackupVaults_605518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCopyJobs_605533 = ref object of OpenApiRestCall_604389
proc url_ListCopyJobs_605535(protocol: Scheme; host: string; base: string;
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

proc validate_ListCopyJobs_605534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605536 = query.getOrDefault("nextToken")
  valid_605536 = validateParameter(valid_605536, JString, required = false,
                                 default = nil)
  if valid_605536 != nil:
    section.add "nextToken", valid_605536
  var valid_605537 = query.getOrDefault("MaxResults")
  valid_605537 = validateParameter(valid_605537, JString, required = false,
                                 default = nil)
  if valid_605537 != nil:
    section.add "MaxResults", valid_605537
  var valid_605538 = query.getOrDefault("state")
  valid_605538 = validateParameter(valid_605538, JString, required = false,
                                 default = newJString("CREATED"))
  if valid_605538 != nil:
    section.add "state", valid_605538
  var valid_605539 = query.getOrDefault("NextToken")
  valid_605539 = validateParameter(valid_605539, JString, required = false,
                                 default = nil)
  if valid_605539 != nil:
    section.add "NextToken", valid_605539
  var valid_605540 = query.getOrDefault("createdAfter")
  valid_605540 = validateParameter(valid_605540, JString, required = false,
                                 default = nil)
  if valid_605540 != nil:
    section.add "createdAfter", valid_605540
  var valid_605541 = query.getOrDefault("resourceType")
  valid_605541 = validateParameter(valid_605541, JString, required = false,
                                 default = nil)
  if valid_605541 != nil:
    section.add "resourceType", valid_605541
  var valid_605542 = query.getOrDefault("destinationVaultArn")
  valid_605542 = validateParameter(valid_605542, JString, required = false,
                                 default = nil)
  if valid_605542 != nil:
    section.add "destinationVaultArn", valid_605542
  var valid_605543 = query.getOrDefault("createdBefore")
  valid_605543 = validateParameter(valid_605543, JString, required = false,
                                 default = nil)
  if valid_605543 != nil:
    section.add "createdBefore", valid_605543
  var valid_605544 = query.getOrDefault("resourceArn")
  valid_605544 = validateParameter(valid_605544, JString, required = false,
                                 default = nil)
  if valid_605544 != nil:
    section.add "resourceArn", valid_605544
  var valid_605545 = query.getOrDefault("maxResults")
  valid_605545 = validateParameter(valid_605545, JInt, required = false, default = nil)
  if valid_605545 != nil:
    section.add "maxResults", valid_605545
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
  var valid_605546 = header.getOrDefault("X-Amz-Signature")
  valid_605546 = validateParameter(valid_605546, JString, required = false,
                                 default = nil)
  if valid_605546 != nil:
    section.add "X-Amz-Signature", valid_605546
  var valid_605547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605547 = validateParameter(valid_605547, JString, required = false,
                                 default = nil)
  if valid_605547 != nil:
    section.add "X-Amz-Content-Sha256", valid_605547
  var valid_605548 = header.getOrDefault("X-Amz-Date")
  valid_605548 = validateParameter(valid_605548, JString, required = false,
                                 default = nil)
  if valid_605548 != nil:
    section.add "X-Amz-Date", valid_605548
  var valid_605549 = header.getOrDefault("X-Amz-Credential")
  valid_605549 = validateParameter(valid_605549, JString, required = false,
                                 default = nil)
  if valid_605549 != nil:
    section.add "X-Amz-Credential", valid_605549
  var valid_605550 = header.getOrDefault("X-Amz-Security-Token")
  valid_605550 = validateParameter(valid_605550, JString, required = false,
                                 default = nil)
  if valid_605550 != nil:
    section.add "X-Amz-Security-Token", valid_605550
  var valid_605551 = header.getOrDefault("X-Amz-Algorithm")
  valid_605551 = validateParameter(valid_605551, JString, required = false,
                                 default = nil)
  if valid_605551 != nil:
    section.add "X-Amz-Algorithm", valid_605551
  var valid_605552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605552 = validateParameter(valid_605552, JString, required = false,
                                 default = nil)
  if valid_605552 != nil:
    section.add "X-Amz-SignedHeaders", valid_605552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605553: Call_ListCopyJobs_605533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about your copy jobs.
  ## 
  let valid = call_605553.validator(path, query, header, formData, body)
  let scheme = call_605553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605553.url(scheme.get, call_605553.host, call_605553.base,
                         call_605553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605553, url, valid)

proc call*(call_605554: Call_ListCopyJobs_605533; nextToken: string = "";
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
  var query_605555 = newJObject()
  add(query_605555, "nextToken", newJString(nextToken))
  add(query_605555, "MaxResults", newJString(MaxResults))
  add(query_605555, "state", newJString(state))
  add(query_605555, "NextToken", newJString(NextToken))
  add(query_605555, "createdAfter", newJString(createdAfter))
  add(query_605555, "resourceType", newJString(resourceType))
  add(query_605555, "destinationVaultArn", newJString(destinationVaultArn))
  add(query_605555, "createdBefore", newJString(createdBefore))
  add(query_605555, "resourceArn", newJString(resourceArn))
  add(query_605555, "maxResults", newJInt(maxResults))
  result = call_605554.call(nil, query_605555, nil, nil, nil)

var listCopyJobs* = Call_ListCopyJobs_605533(name: "listCopyJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/copy-jobs/",
    validator: validate_ListCopyJobs_605534, base: "/", url: url_ListCopyJobs_605535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProtectedResources_605556 = ref object of OpenApiRestCall_604389
proc url_ListProtectedResources_605558(protocol: Scheme; host: string; base: string;
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

proc validate_ListProtectedResources_605557(path: JsonNode; query: JsonNode;
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
  var valid_605559 = query.getOrDefault("nextToken")
  valid_605559 = validateParameter(valid_605559, JString, required = false,
                                 default = nil)
  if valid_605559 != nil:
    section.add "nextToken", valid_605559
  var valid_605560 = query.getOrDefault("MaxResults")
  valid_605560 = validateParameter(valid_605560, JString, required = false,
                                 default = nil)
  if valid_605560 != nil:
    section.add "MaxResults", valid_605560
  var valid_605561 = query.getOrDefault("NextToken")
  valid_605561 = validateParameter(valid_605561, JString, required = false,
                                 default = nil)
  if valid_605561 != nil:
    section.add "NextToken", valid_605561
  var valid_605562 = query.getOrDefault("maxResults")
  valid_605562 = validateParameter(valid_605562, JInt, required = false, default = nil)
  if valid_605562 != nil:
    section.add "maxResults", valid_605562
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
  var valid_605563 = header.getOrDefault("X-Amz-Signature")
  valid_605563 = validateParameter(valid_605563, JString, required = false,
                                 default = nil)
  if valid_605563 != nil:
    section.add "X-Amz-Signature", valid_605563
  var valid_605564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605564 = validateParameter(valid_605564, JString, required = false,
                                 default = nil)
  if valid_605564 != nil:
    section.add "X-Amz-Content-Sha256", valid_605564
  var valid_605565 = header.getOrDefault("X-Amz-Date")
  valid_605565 = validateParameter(valid_605565, JString, required = false,
                                 default = nil)
  if valid_605565 != nil:
    section.add "X-Amz-Date", valid_605565
  var valid_605566 = header.getOrDefault("X-Amz-Credential")
  valid_605566 = validateParameter(valid_605566, JString, required = false,
                                 default = nil)
  if valid_605566 != nil:
    section.add "X-Amz-Credential", valid_605566
  var valid_605567 = header.getOrDefault("X-Amz-Security-Token")
  valid_605567 = validateParameter(valid_605567, JString, required = false,
                                 default = nil)
  if valid_605567 != nil:
    section.add "X-Amz-Security-Token", valid_605567
  var valid_605568 = header.getOrDefault("X-Amz-Algorithm")
  valid_605568 = validateParameter(valid_605568, JString, required = false,
                                 default = nil)
  if valid_605568 != nil:
    section.add "X-Amz-Algorithm", valid_605568
  var valid_605569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605569 = validateParameter(valid_605569, JString, required = false,
                                 default = nil)
  if valid_605569 != nil:
    section.add "X-Amz-SignedHeaders", valid_605569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605570: Call_ListProtectedResources_605556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources successfully backed up by AWS Backup, including the time the resource was saved, an Amazon Resource Name (ARN) of the resource, and a resource type.
  ## 
  let valid = call_605570.validator(path, query, header, formData, body)
  let scheme = call_605570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605570.url(scheme.get, call_605570.host, call_605570.base,
                         call_605570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605570, url, valid)

proc call*(call_605571: Call_ListProtectedResources_605556; nextToken: string = "";
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
  var query_605572 = newJObject()
  add(query_605572, "nextToken", newJString(nextToken))
  add(query_605572, "MaxResults", newJString(MaxResults))
  add(query_605572, "NextToken", newJString(NextToken))
  add(query_605572, "maxResults", newJInt(maxResults))
  result = call_605571.call(nil, query_605572, nil, nil, nil)

var listProtectedResources* = Call_ListProtectedResources_605556(
    name: "listProtectedResources", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com", route: "/resources/",
    validator: validate_ListProtectedResources_605557, base: "/",
    url: url_ListProtectedResources_605558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByBackupVault_605573 = ref object of OpenApiRestCall_604389
proc url_ListRecoveryPointsByBackupVault_605575(protocol: Scheme; host: string;
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

proc validate_ListRecoveryPointsByBackupVault_605574(path: JsonNode;
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
  var valid_605576 = path.getOrDefault("backupVaultName")
  valid_605576 = validateParameter(valid_605576, JString, required = true,
                                 default = nil)
  if valid_605576 != nil:
    section.add "backupVaultName", valid_605576
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
  var valid_605577 = query.getOrDefault("nextToken")
  valid_605577 = validateParameter(valid_605577, JString, required = false,
                                 default = nil)
  if valid_605577 != nil:
    section.add "nextToken", valid_605577
  var valid_605578 = query.getOrDefault("MaxResults")
  valid_605578 = validateParameter(valid_605578, JString, required = false,
                                 default = nil)
  if valid_605578 != nil:
    section.add "MaxResults", valid_605578
  var valid_605579 = query.getOrDefault("backupPlanId")
  valid_605579 = validateParameter(valid_605579, JString, required = false,
                                 default = nil)
  if valid_605579 != nil:
    section.add "backupPlanId", valid_605579
  var valid_605580 = query.getOrDefault("NextToken")
  valid_605580 = validateParameter(valid_605580, JString, required = false,
                                 default = nil)
  if valid_605580 != nil:
    section.add "NextToken", valid_605580
  var valid_605581 = query.getOrDefault("createdAfter")
  valid_605581 = validateParameter(valid_605581, JString, required = false,
                                 default = nil)
  if valid_605581 != nil:
    section.add "createdAfter", valid_605581
  var valid_605582 = query.getOrDefault("resourceType")
  valid_605582 = validateParameter(valid_605582, JString, required = false,
                                 default = nil)
  if valid_605582 != nil:
    section.add "resourceType", valid_605582
  var valid_605583 = query.getOrDefault("createdBefore")
  valid_605583 = validateParameter(valid_605583, JString, required = false,
                                 default = nil)
  if valid_605583 != nil:
    section.add "createdBefore", valid_605583
  var valid_605584 = query.getOrDefault("resourceArn")
  valid_605584 = validateParameter(valid_605584, JString, required = false,
                                 default = nil)
  if valid_605584 != nil:
    section.add "resourceArn", valid_605584
  var valid_605585 = query.getOrDefault("maxResults")
  valid_605585 = validateParameter(valid_605585, JInt, required = false, default = nil)
  if valid_605585 != nil:
    section.add "maxResults", valid_605585
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
  var valid_605586 = header.getOrDefault("X-Amz-Signature")
  valid_605586 = validateParameter(valid_605586, JString, required = false,
                                 default = nil)
  if valid_605586 != nil:
    section.add "X-Amz-Signature", valid_605586
  var valid_605587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605587 = validateParameter(valid_605587, JString, required = false,
                                 default = nil)
  if valid_605587 != nil:
    section.add "X-Amz-Content-Sha256", valid_605587
  var valid_605588 = header.getOrDefault("X-Amz-Date")
  valid_605588 = validateParameter(valid_605588, JString, required = false,
                                 default = nil)
  if valid_605588 != nil:
    section.add "X-Amz-Date", valid_605588
  var valid_605589 = header.getOrDefault("X-Amz-Credential")
  valid_605589 = validateParameter(valid_605589, JString, required = false,
                                 default = nil)
  if valid_605589 != nil:
    section.add "X-Amz-Credential", valid_605589
  var valid_605590 = header.getOrDefault("X-Amz-Security-Token")
  valid_605590 = validateParameter(valid_605590, JString, required = false,
                                 default = nil)
  if valid_605590 != nil:
    section.add "X-Amz-Security-Token", valid_605590
  var valid_605591 = header.getOrDefault("X-Amz-Algorithm")
  valid_605591 = validateParameter(valid_605591, JString, required = false,
                                 default = nil)
  if valid_605591 != nil:
    section.add "X-Amz-Algorithm", valid_605591
  var valid_605592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605592 = validateParameter(valid_605592, JString, required = false,
                                 default = nil)
  if valid_605592 != nil:
    section.add "X-Amz-SignedHeaders", valid_605592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605593: Call_ListRecoveryPointsByBackupVault_605573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns detailed information about the recovery points stored in a backup vault.
  ## 
  let valid = call_605593.validator(path, query, header, formData, body)
  let scheme = call_605593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605593.url(scheme.get, call_605593.host, call_605593.base,
                         call_605593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605593, url, valid)

proc call*(call_605594: Call_ListRecoveryPointsByBackupVault_605573;
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
  var path_605595 = newJObject()
  var query_605596 = newJObject()
  add(query_605596, "nextToken", newJString(nextToken))
  add(query_605596, "MaxResults", newJString(MaxResults))
  add(path_605595, "backupVaultName", newJString(backupVaultName))
  add(query_605596, "backupPlanId", newJString(backupPlanId))
  add(query_605596, "NextToken", newJString(NextToken))
  add(query_605596, "createdAfter", newJString(createdAfter))
  add(query_605596, "resourceType", newJString(resourceType))
  add(query_605596, "createdBefore", newJString(createdBefore))
  add(query_605596, "resourceArn", newJString(resourceArn))
  add(query_605596, "maxResults", newJInt(maxResults))
  result = call_605594.call(path_605595, query_605596, nil, nil, nil)

var listRecoveryPointsByBackupVault* = Call_ListRecoveryPointsByBackupVault_605573(
    name: "listRecoveryPointsByBackupVault", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/backup-vaults/{backupVaultName}/recovery-points/",
    validator: validate_ListRecoveryPointsByBackupVault_605574, base: "/",
    url: url_ListRecoveryPointsByBackupVault_605575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRecoveryPointsByResource_605597 = ref object of OpenApiRestCall_604389
proc url_ListRecoveryPointsByResource_605599(protocol: Scheme; host: string;
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

proc validate_ListRecoveryPointsByResource_605598(path: JsonNode; query: JsonNode;
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
  var valid_605600 = path.getOrDefault("resourceArn")
  valid_605600 = validateParameter(valid_605600, JString, required = true,
                                 default = nil)
  if valid_605600 != nil:
    section.add "resourceArn", valid_605600
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
  var valid_605601 = query.getOrDefault("nextToken")
  valid_605601 = validateParameter(valid_605601, JString, required = false,
                                 default = nil)
  if valid_605601 != nil:
    section.add "nextToken", valid_605601
  var valid_605602 = query.getOrDefault("MaxResults")
  valid_605602 = validateParameter(valid_605602, JString, required = false,
                                 default = nil)
  if valid_605602 != nil:
    section.add "MaxResults", valid_605602
  var valid_605603 = query.getOrDefault("NextToken")
  valid_605603 = validateParameter(valid_605603, JString, required = false,
                                 default = nil)
  if valid_605603 != nil:
    section.add "NextToken", valid_605603
  var valid_605604 = query.getOrDefault("maxResults")
  valid_605604 = validateParameter(valid_605604, JInt, required = false, default = nil)
  if valid_605604 != nil:
    section.add "maxResults", valid_605604
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
  var valid_605605 = header.getOrDefault("X-Amz-Signature")
  valid_605605 = validateParameter(valid_605605, JString, required = false,
                                 default = nil)
  if valid_605605 != nil:
    section.add "X-Amz-Signature", valid_605605
  var valid_605606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605606 = validateParameter(valid_605606, JString, required = false,
                                 default = nil)
  if valid_605606 != nil:
    section.add "X-Amz-Content-Sha256", valid_605606
  var valid_605607 = header.getOrDefault("X-Amz-Date")
  valid_605607 = validateParameter(valid_605607, JString, required = false,
                                 default = nil)
  if valid_605607 != nil:
    section.add "X-Amz-Date", valid_605607
  var valid_605608 = header.getOrDefault("X-Amz-Credential")
  valid_605608 = validateParameter(valid_605608, JString, required = false,
                                 default = nil)
  if valid_605608 != nil:
    section.add "X-Amz-Credential", valid_605608
  var valid_605609 = header.getOrDefault("X-Amz-Security-Token")
  valid_605609 = validateParameter(valid_605609, JString, required = false,
                                 default = nil)
  if valid_605609 != nil:
    section.add "X-Amz-Security-Token", valid_605609
  var valid_605610 = header.getOrDefault("X-Amz-Algorithm")
  valid_605610 = validateParameter(valid_605610, JString, required = false,
                                 default = nil)
  if valid_605610 != nil:
    section.add "X-Amz-Algorithm", valid_605610
  var valid_605611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605611 = validateParameter(valid_605611, JString, required = false,
                                 default = nil)
  if valid_605611 != nil:
    section.add "X-Amz-SignedHeaders", valid_605611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605612: Call_ListRecoveryPointsByResource_605597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed information about recovery points of the type specified by a resource Amazon Resource Name (ARN).
  ## 
  let valid = call_605612.validator(path, query, header, formData, body)
  let scheme = call_605612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605612.url(scheme.get, call_605612.host, call_605612.base,
                         call_605612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605612, url, valid)

proc call*(call_605613: Call_ListRecoveryPointsByResource_605597;
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
  var path_605614 = newJObject()
  var query_605615 = newJObject()
  add(query_605615, "nextToken", newJString(nextToken))
  add(query_605615, "MaxResults", newJString(MaxResults))
  add(path_605614, "resourceArn", newJString(resourceArn))
  add(query_605615, "NextToken", newJString(NextToken))
  add(query_605615, "maxResults", newJInt(maxResults))
  result = call_605613.call(path_605614, query_605615, nil, nil, nil)

var listRecoveryPointsByResource* = Call_ListRecoveryPointsByResource_605597(
    name: "listRecoveryPointsByResource", meth: HttpMethod.HttpGet,
    host: "backup.amazonaws.com",
    route: "/resources/{resourceArn}/recovery-points/",
    validator: validate_ListRecoveryPointsByResource_605598, base: "/",
    url: url_ListRecoveryPointsByResource_605599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRestoreJobs_605616 = ref object of OpenApiRestCall_604389
proc url_ListRestoreJobs_605618(protocol: Scheme; host: string; base: string;
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

proc validate_ListRestoreJobs_605617(path: JsonNode; query: JsonNode;
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
  var valid_605619 = query.getOrDefault("nextToken")
  valid_605619 = validateParameter(valid_605619, JString, required = false,
                                 default = nil)
  if valid_605619 != nil:
    section.add "nextToken", valid_605619
  var valid_605620 = query.getOrDefault("MaxResults")
  valid_605620 = validateParameter(valid_605620, JString, required = false,
                                 default = nil)
  if valid_605620 != nil:
    section.add "MaxResults", valid_605620
  var valid_605621 = query.getOrDefault("NextToken")
  valid_605621 = validateParameter(valid_605621, JString, required = false,
                                 default = nil)
  if valid_605621 != nil:
    section.add "NextToken", valid_605621
  var valid_605622 = query.getOrDefault("maxResults")
  valid_605622 = validateParameter(valid_605622, JInt, required = false, default = nil)
  if valid_605622 != nil:
    section.add "maxResults", valid_605622
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
  var valid_605623 = header.getOrDefault("X-Amz-Signature")
  valid_605623 = validateParameter(valid_605623, JString, required = false,
                                 default = nil)
  if valid_605623 != nil:
    section.add "X-Amz-Signature", valid_605623
  var valid_605624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605624 = validateParameter(valid_605624, JString, required = false,
                                 default = nil)
  if valid_605624 != nil:
    section.add "X-Amz-Content-Sha256", valid_605624
  var valid_605625 = header.getOrDefault("X-Amz-Date")
  valid_605625 = validateParameter(valid_605625, JString, required = false,
                                 default = nil)
  if valid_605625 != nil:
    section.add "X-Amz-Date", valid_605625
  var valid_605626 = header.getOrDefault("X-Amz-Credential")
  valid_605626 = validateParameter(valid_605626, JString, required = false,
                                 default = nil)
  if valid_605626 != nil:
    section.add "X-Amz-Credential", valid_605626
  var valid_605627 = header.getOrDefault("X-Amz-Security-Token")
  valid_605627 = validateParameter(valid_605627, JString, required = false,
                                 default = nil)
  if valid_605627 != nil:
    section.add "X-Amz-Security-Token", valid_605627
  var valid_605628 = header.getOrDefault("X-Amz-Algorithm")
  valid_605628 = validateParameter(valid_605628, JString, required = false,
                                 default = nil)
  if valid_605628 != nil:
    section.add "X-Amz-Algorithm", valid_605628
  var valid_605629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605629 = validateParameter(valid_605629, JString, required = false,
                                 default = nil)
  if valid_605629 != nil:
    section.add "X-Amz-SignedHeaders", valid_605629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605630: Call_ListRestoreJobs_605616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of jobs that AWS Backup initiated to restore a saved resource, including metadata about the recovery process.
  ## 
  let valid = call_605630.validator(path, query, header, formData, body)
  let scheme = call_605630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605630.url(scheme.get, call_605630.host, call_605630.base,
                         call_605630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605630, url, valid)

proc call*(call_605631: Call_ListRestoreJobs_605616; nextToken: string = "";
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
  var query_605632 = newJObject()
  add(query_605632, "nextToken", newJString(nextToken))
  add(query_605632, "MaxResults", newJString(MaxResults))
  add(query_605632, "NextToken", newJString(NextToken))
  add(query_605632, "maxResults", newJInt(maxResults))
  result = call_605631.call(nil, query_605632, nil, nil, nil)

var listRestoreJobs* = Call_ListRestoreJobs_605616(name: "listRestoreJobs",
    meth: HttpMethod.HttpGet, host: "backup.amazonaws.com", route: "/restore-jobs/",
    validator: validate_ListRestoreJobs_605617, base: "/", url: url_ListRestoreJobs_605618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_605633 = ref object of OpenApiRestCall_604389
proc url_ListTags_605635(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_605634(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605636 = path.getOrDefault("resourceArn")
  valid_605636 = validateParameter(valid_605636, JString, required = true,
                                 default = nil)
  if valid_605636 != nil:
    section.add "resourceArn", valid_605636
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
  var valid_605637 = query.getOrDefault("nextToken")
  valid_605637 = validateParameter(valid_605637, JString, required = false,
                                 default = nil)
  if valid_605637 != nil:
    section.add "nextToken", valid_605637
  var valid_605638 = query.getOrDefault("MaxResults")
  valid_605638 = validateParameter(valid_605638, JString, required = false,
                                 default = nil)
  if valid_605638 != nil:
    section.add "MaxResults", valid_605638
  var valid_605639 = query.getOrDefault("NextToken")
  valid_605639 = validateParameter(valid_605639, JString, required = false,
                                 default = nil)
  if valid_605639 != nil:
    section.add "NextToken", valid_605639
  var valid_605640 = query.getOrDefault("maxResults")
  valid_605640 = validateParameter(valid_605640, JInt, required = false, default = nil)
  if valid_605640 != nil:
    section.add "maxResults", valid_605640
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
  var valid_605641 = header.getOrDefault("X-Amz-Signature")
  valid_605641 = validateParameter(valid_605641, JString, required = false,
                                 default = nil)
  if valid_605641 != nil:
    section.add "X-Amz-Signature", valid_605641
  var valid_605642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605642 = validateParameter(valid_605642, JString, required = false,
                                 default = nil)
  if valid_605642 != nil:
    section.add "X-Amz-Content-Sha256", valid_605642
  var valid_605643 = header.getOrDefault("X-Amz-Date")
  valid_605643 = validateParameter(valid_605643, JString, required = false,
                                 default = nil)
  if valid_605643 != nil:
    section.add "X-Amz-Date", valid_605643
  var valid_605644 = header.getOrDefault("X-Amz-Credential")
  valid_605644 = validateParameter(valid_605644, JString, required = false,
                                 default = nil)
  if valid_605644 != nil:
    section.add "X-Amz-Credential", valid_605644
  var valid_605645 = header.getOrDefault("X-Amz-Security-Token")
  valid_605645 = validateParameter(valid_605645, JString, required = false,
                                 default = nil)
  if valid_605645 != nil:
    section.add "X-Amz-Security-Token", valid_605645
  var valid_605646 = header.getOrDefault("X-Amz-Algorithm")
  valid_605646 = validateParameter(valid_605646, JString, required = false,
                                 default = nil)
  if valid_605646 != nil:
    section.add "X-Amz-Algorithm", valid_605646
  var valid_605647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605647 = validateParameter(valid_605647, JString, required = false,
                                 default = nil)
  if valid_605647 != nil:
    section.add "X-Amz-SignedHeaders", valid_605647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605648: Call_ListTags_605633; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of key-value pairs assigned to a target recovery point, backup plan, or backup vault.
  ## 
  let valid = call_605648.validator(path, query, header, formData, body)
  let scheme = call_605648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605648.url(scheme.get, call_605648.host, call_605648.base,
                         call_605648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605648, url, valid)

proc call*(call_605649: Call_ListTags_605633; resourceArn: string;
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
  var path_605650 = newJObject()
  var query_605651 = newJObject()
  add(query_605651, "nextToken", newJString(nextToken))
  add(query_605651, "MaxResults", newJString(MaxResults))
  add(path_605650, "resourceArn", newJString(resourceArn))
  add(query_605651, "NextToken", newJString(NextToken))
  add(query_605651, "maxResults", newJInt(maxResults))
  result = call_605649.call(path_605650, query_605651, nil, nil, nil)

var listTags* = Call_ListTags_605633(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "backup.amazonaws.com",
                                  route: "/tags/{resourceArn}/",
                                  validator: validate_ListTags_605634, base: "/",
                                  url: url_ListTags_605635,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartBackupJob_605652 = ref object of OpenApiRestCall_604389
proc url_StartBackupJob_605654(protocol: Scheme; host: string; base: string;
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

proc validate_StartBackupJob_605653(path: JsonNode; query: JsonNode;
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
  var valid_605655 = header.getOrDefault("X-Amz-Signature")
  valid_605655 = validateParameter(valid_605655, JString, required = false,
                                 default = nil)
  if valid_605655 != nil:
    section.add "X-Amz-Signature", valid_605655
  var valid_605656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605656 = validateParameter(valid_605656, JString, required = false,
                                 default = nil)
  if valid_605656 != nil:
    section.add "X-Amz-Content-Sha256", valid_605656
  var valid_605657 = header.getOrDefault("X-Amz-Date")
  valid_605657 = validateParameter(valid_605657, JString, required = false,
                                 default = nil)
  if valid_605657 != nil:
    section.add "X-Amz-Date", valid_605657
  var valid_605658 = header.getOrDefault("X-Amz-Credential")
  valid_605658 = validateParameter(valid_605658, JString, required = false,
                                 default = nil)
  if valid_605658 != nil:
    section.add "X-Amz-Credential", valid_605658
  var valid_605659 = header.getOrDefault("X-Amz-Security-Token")
  valid_605659 = validateParameter(valid_605659, JString, required = false,
                                 default = nil)
  if valid_605659 != nil:
    section.add "X-Amz-Security-Token", valid_605659
  var valid_605660 = header.getOrDefault("X-Amz-Algorithm")
  valid_605660 = validateParameter(valid_605660, JString, required = false,
                                 default = nil)
  if valid_605660 != nil:
    section.add "X-Amz-Algorithm", valid_605660
  var valid_605661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605661 = validateParameter(valid_605661, JString, required = false,
                                 default = nil)
  if valid_605661 != nil:
    section.add "X-Amz-SignedHeaders", valid_605661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605663: Call_StartBackupJob_605652; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time backup of the specified resource.
  ## 
  let valid = call_605663.validator(path, query, header, formData, body)
  let scheme = call_605663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605663.url(scheme.get, call_605663.host, call_605663.base,
                         call_605663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605663, url, valid)

proc call*(call_605664: Call_StartBackupJob_605652; body: JsonNode): Recallable =
  ## startBackupJob
  ## Starts a job to create a one-time backup of the specified resource.
  ##   body: JObject (required)
  var body_605665 = newJObject()
  if body != nil:
    body_605665 = body
  result = call_605664.call(nil, nil, nil, nil, body_605665)

var startBackupJob* = Call_StartBackupJob_605652(name: "startBackupJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/backup-jobs",
    validator: validate_StartBackupJob_605653, base: "/", url: url_StartBackupJob_605654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCopyJob_605666 = ref object of OpenApiRestCall_604389
proc url_StartCopyJob_605668(protocol: Scheme; host: string; base: string;
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

proc validate_StartCopyJob_605667(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605669 = header.getOrDefault("X-Amz-Signature")
  valid_605669 = validateParameter(valid_605669, JString, required = false,
                                 default = nil)
  if valid_605669 != nil:
    section.add "X-Amz-Signature", valid_605669
  var valid_605670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605670 = validateParameter(valid_605670, JString, required = false,
                                 default = nil)
  if valid_605670 != nil:
    section.add "X-Amz-Content-Sha256", valid_605670
  var valid_605671 = header.getOrDefault("X-Amz-Date")
  valid_605671 = validateParameter(valid_605671, JString, required = false,
                                 default = nil)
  if valid_605671 != nil:
    section.add "X-Amz-Date", valid_605671
  var valid_605672 = header.getOrDefault("X-Amz-Credential")
  valid_605672 = validateParameter(valid_605672, JString, required = false,
                                 default = nil)
  if valid_605672 != nil:
    section.add "X-Amz-Credential", valid_605672
  var valid_605673 = header.getOrDefault("X-Amz-Security-Token")
  valid_605673 = validateParameter(valid_605673, JString, required = false,
                                 default = nil)
  if valid_605673 != nil:
    section.add "X-Amz-Security-Token", valid_605673
  var valid_605674 = header.getOrDefault("X-Amz-Algorithm")
  valid_605674 = validateParameter(valid_605674, JString, required = false,
                                 default = nil)
  if valid_605674 != nil:
    section.add "X-Amz-Algorithm", valid_605674
  var valid_605675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605675 = validateParameter(valid_605675, JString, required = false,
                                 default = nil)
  if valid_605675 != nil:
    section.add "X-Amz-SignedHeaders", valid_605675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605677: Call_StartCopyJob_605666; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to create a one-time copy of the specified resource.
  ## 
  let valid = call_605677.validator(path, query, header, formData, body)
  let scheme = call_605677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605677.url(scheme.get, call_605677.host, call_605677.base,
                         call_605677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605677, url, valid)

proc call*(call_605678: Call_StartCopyJob_605666; body: JsonNode): Recallable =
  ## startCopyJob
  ## Starts a job to create a one-time copy of the specified resource.
  ##   body: JObject (required)
  var body_605679 = newJObject()
  if body != nil:
    body_605679 = body
  result = call_605678.call(nil, nil, nil, nil, body_605679)

var startCopyJob* = Call_StartCopyJob_605666(name: "startCopyJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/copy-jobs",
    validator: validate_StartCopyJob_605667, base: "/", url: url_StartCopyJob_605668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRestoreJob_605680 = ref object of OpenApiRestCall_604389
proc url_StartRestoreJob_605682(protocol: Scheme; host: string; base: string;
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

proc validate_StartRestoreJob_605681(path: JsonNode; query: JsonNode;
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
  var valid_605683 = header.getOrDefault("X-Amz-Signature")
  valid_605683 = validateParameter(valid_605683, JString, required = false,
                                 default = nil)
  if valid_605683 != nil:
    section.add "X-Amz-Signature", valid_605683
  var valid_605684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605684 = validateParameter(valid_605684, JString, required = false,
                                 default = nil)
  if valid_605684 != nil:
    section.add "X-Amz-Content-Sha256", valid_605684
  var valid_605685 = header.getOrDefault("X-Amz-Date")
  valid_605685 = validateParameter(valid_605685, JString, required = false,
                                 default = nil)
  if valid_605685 != nil:
    section.add "X-Amz-Date", valid_605685
  var valid_605686 = header.getOrDefault("X-Amz-Credential")
  valid_605686 = validateParameter(valid_605686, JString, required = false,
                                 default = nil)
  if valid_605686 != nil:
    section.add "X-Amz-Credential", valid_605686
  var valid_605687 = header.getOrDefault("X-Amz-Security-Token")
  valid_605687 = validateParameter(valid_605687, JString, required = false,
                                 default = nil)
  if valid_605687 != nil:
    section.add "X-Amz-Security-Token", valid_605687
  var valid_605688 = header.getOrDefault("X-Amz-Algorithm")
  valid_605688 = validateParameter(valid_605688, JString, required = false,
                                 default = nil)
  if valid_605688 != nil:
    section.add "X-Amz-Algorithm", valid_605688
  var valid_605689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605689 = validateParameter(valid_605689, JString, required = false,
                                 default = nil)
  if valid_605689 != nil:
    section.add "X-Amz-SignedHeaders", valid_605689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605691: Call_StartRestoreJob_605680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ## 
  let valid = call_605691.validator(path, query, header, formData, body)
  let scheme = call_605691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605691.url(scheme.get, call_605691.host, call_605691.base,
                         call_605691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605691, url, valid)

proc call*(call_605692: Call_StartRestoreJob_605680; body: JsonNode): Recallable =
  ## startRestoreJob
  ## <p>Recovers the saved resource identified by an Amazon Resource Name (ARN). </p> <p>If the resource ARN is included in the request, then the last complete backup of that resource is recovered. If the ARN of a recovery point is supplied, then that recovery point is restored.</p>
  ##   body: JObject (required)
  var body_605693 = newJObject()
  if body != nil:
    body_605693 = body
  result = call_605692.call(nil, nil, nil, nil, body_605693)

var startRestoreJob* = Call_StartRestoreJob_605680(name: "startRestoreJob",
    meth: HttpMethod.HttpPut, host: "backup.amazonaws.com", route: "/restore-jobs",
    validator: validate_StartRestoreJob_605681, base: "/", url: url_StartRestoreJob_605682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_605694 = ref object of OpenApiRestCall_604389
proc url_TagResource_605696(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_605695(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605697 = path.getOrDefault("resourceArn")
  valid_605697 = validateParameter(valid_605697, JString, required = true,
                                 default = nil)
  if valid_605697 != nil:
    section.add "resourceArn", valid_605697
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
  var valid_605698 = header.getOrDefault("X-Amz-Signature")
  valid_605698 = validateParameter(valid_605698, JString, required = false,
                                 default = nil)
  if valid_605698 != nil:
    section.add "X-Amz-Signature", valid_605698
  var valid_605699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605699 = validateParameter(valid_605699, JString, required = false,
                                 default = nil)
  if valid_605699 != nil:
    section.add "X-Amz-Content-Sha256", valid_605699
  var valid_605700 = header.getOrDefault("X-Amz-Date")
  valid_605700 = validateParameter(valid_605700, JString, required = false,
                                 default = nil)
  if valid_605700 != nil:
    section.add "X-Amz-Date", valid_605700
  var valid_605701 = header.getOrDefault("X-Amz-Credential")
  valid_605701 = validateParameter(valid_605701, JString, required = false,
                                 default = nil)
  if valid_605701 != nil:
    section.add "X-Amz-Credential", valid_605701
  var valid_605702 = header.getOrDefault("X-Amz-Security-Token")
  valid_605702 = validateParameter(valid_605702, JString, required = false,
                                 default = nil)
  if valid_605702 != nil:
    section.add "X-Amz-Security-Token", valid_605702
  var valid_605703 = header.getOrDefault("X-Amz-Algorithm")
  valid_605703 = validateParameter(valid_605703, JString, required = false,
                                 default = nil)
  if valid_605703 != nil:
    section.add "X-Amz-Algorithm", valid_605703
  var valid_605704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605704 = validateParameter(valid_605704, JString, required = false,
                                 default = nil)
  if valid_605704 != nil:
    section.add "X-Amz-SignedHeaders", valid_605704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605706: Call_TagResource_605694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ## 
  let valid = call_605706.validator(path, query, header, formData, body)
  let scheme = call_605706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605706.url(scheme.get, call_605706.host, call_605706.base,
                         call_605706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605706, url, valid)

proc call*(call_605707: Call_TagResource_605694; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Assigns a set of key-value pairs to a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN).
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_605708 = newJObject()
  var body_605709 = newJObject()
  add(path_605708, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_605709 = body
  result = call_605707.call(path_605708, nil, nil, nil, body_605709)

var tagResource* = Call_TagResource_605694(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "backup.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_605695,
                                        base: "/", url: url_TagResource_605696,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_605710 = ref object of OpenApiRestCall_604389
proc url_UntagResource_605712(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_605711(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605713 = path.getOrDefault("resourceArn")
  valid_605713 = validateParameter(valid_605713, JString, required = true,
                                 default = nil)
  if valid_605713 != nil:
    section.add "resourceArn", valid_605713
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
  var valid_605714 = header.getOrDefault("X-Amz-Signature")
  valid_605714 = validateParameter(valid_605714, JString, required = false,
                                 default = nil)
  if valid_605714 != nil:
    section.add "X-Amz-Signature", valid_605714
  var valid_605715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605715 = validateParameter(valid_605715, JString, required = false,
                                 default = nil)
  if valid_605715 != nil:
    section.add "X-Amz-Content-Sha256", valid_605715
  var valid_605716 = header.getOrDefault("X-Amz-Date")
  valid_605716 = validateParameter(valid_605716, JString, required = false,
                                 default = nil)
  if valid_605716 != nil:
    section.add "X-Amz-Date", valid_605716
  var valid_605717 = header.getOrDefault("X-Amz-Credential")
  valid_605717 = validateParameter(valid_605717, JString, required = false,
                                 default = nil)
  if valid_605717 != nil:
    section.add "X-Amz-Credential", valid_605717
  var valid_605718 = header.getOrDefault("X-Amz-Security-Token")
  valid_605718 = validateParameter(valid_605718, JString, required = false,
                                 default = nil)
  if valid_605718 != nil:
    section.add "X-Amz-Security-Token", valid_605718
  var valid_605719 = header.getOrDefault("X-Amz-Algorithm")
  valid_605719 = validateParameter(valid_605719, JString, required = false,
                                 default = nil)
  if valid_605719 != nil:
    section.add "X-Amz-Algorithm", valid_605719
  var valid_605720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605720 = validateParameter(valid_605720, JString, required = false,
                                 default = nil)
  if valid_605720 != nil:
    section.add "X-Amz-SignedHeaders", valid_605720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605722: Call_UntagResource_605710; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ## 
  let valid = call_605722.validator(path, query, header, formData, body)
  let scheme = call_605722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605722.url(scheme.get, call_605722.host, call_605722.base,
                         call_605722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605722, url, valid)

proc call*(call_605723: Call_UntagResource_605710; resourceArn: string;
          body: JsonNode): Recallable =
  ## untagResource
  ## Removes a set of key-value pairs from a recovery point, backup plan, or backup vault identified by an Amazon Resource Name (ARN)
  ##   resourceArn: string (required)
  ##              : An ARN that uniquely identifies a resource. The format of the ARN depends on the type of the tagged resource.
  ##   body: JObject (required)
  var path_605724 = newJObject()
  var body_605725 = newJObject()
  add(path_605724, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_605725 = body
  result = call_605723.call(path_605724, nil, nil, nil, body_605725)

var untagResource* = Call_UntagResource_605710(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "backup.amazonaws.com",
    route: "/untag/{resourceArn}", validator: validate_UntagResource_605711,
    base: "/", url: url_UntagResource_605712, schemes: {Scheme.Https, Scheme.Http})
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
