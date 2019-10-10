
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Route 53
## version: 2013-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon Route 53 is a highly available and scalable Domain Name System (DNS) web service.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/route53/
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "route53"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateVPCWithHostedZone_602803 = ref object of OpenApiRestCall_602466
proc url_AssociateVPCWithHostedZone_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/associatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_AssociateVPCWithHostedZone_602804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602931 = path.getOrDefault("Id")
  valid_602931 = validateParameter(valid_602931, JString, required = true,
                                 default = nil)
  if valid_602931 != nil:
    section.add "Id", valid_602931
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602932 = header.getOrDefault("X-Amz-Date")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Date", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Security-Token")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Security-Token", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Content-Sha256", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Algorithm")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Algorithm", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Signature")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Signature", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-SignedHeaders", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Credential")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Credential", valid_602938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602962: Call_AssociateVPCWithHostedZone_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  let valid = call_602962.validator(path, query, header, formData, body)
  let scheme = call_602962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602962.url(scheme.get, call_602962.host, call_602962.base,
                         call_602962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602962, url, valid)

proc call*(call_603033: Call_AssociateVPCWithHostedZone_602803; Id: string;
          body: JsonNode): Recallable =
  ## associateVPCWithHostedZone
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ##   Id: string (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  ##   body: JObject (required)
  var path_603034 = newJObject()
  var body_603036 = newJObject()
  add(path_603034, "Id", newJString(Id))
  if body != nil:
    body_603036 = body
  result = call_603033.call(path_603034, nil, nil, nil, body_603036)

var associateVPCWithHostedZone* = Call_AssociateVPCWithHostedZone_602803(
    name: "associateVPCWithHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/associatevpc",
    validator: validate_AssociateVPCWithHostedZone_602804, base: "/",
    url: url_AssociateVPCWithHostedZone_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeResourceRecordSets_603075 = ref object of OpenApiRestCall_602466
proc url_ChangeResourceRecordSets_603077(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ChangeResourceRecordSets_603076(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603078 = path.getOrDefault("Id")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = nil)
  if valid_603078 != nil:
    section.add "Id", valid_603078
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603079 = header.getOrDefault("X-Amz-Date")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Date", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Security-Token")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Security-Token", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Content-Sha256", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Algorithm")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Algorithm", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Signature")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Signature", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-SignedHeaders", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Credential")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Credential", valid_603085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603087: Call_ChangeResourceRecordSets_603075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_603087.validator(path, query, header, formData, body)
  let scheme = call_603087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603087.url(scheme.get, call_603087.host, call_603087.base,
                         call_603087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603087, url, valid)

proc call*(call_603088: Call_ChangeResourceRecordSets_603075; Id: string;
          body: JsonNode): Recallable =
  ## changeResourceRecordSets
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  ##   body: JObject (required)
  var path_603089 = newJObject()
  var body_603090 = newJObject()
  add(path_603089, "Id", newJString(Id))
  if body != nil:
    body_603090 = body
  result = call_603088.call(path_603089, nil, nil, nil, body_603090)

var changeResourceRecordSets* = Call_ChangeResourceRecordSets_603075(
    name: "changeResourceRecordSets", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset/",
    validator: validate_ChangeResourceRecordSets_603076, base: "/",
    url: url_ChangeResourceRecordSets_603077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeTagsForResource_603119 = ref object of OpenApiRestCall_602466
proc url_ChangeTagsForResource_603121(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ChangeTagsForResource_603120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceType` field"
  var valid_603122 = path.getOrDefault("ResourceType")
  valid_603122 = validateParameter(valid_603122, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_603122 != nil:
    section.add "ResourceType", valid_603122
  var valid_603123 = path.getOrDefault("ResourceId")
  valid_603123 = validateParameter(valid_603123, JString, required = true,
                                 default = nil)
  if valid_603123 != nil:
    section.add "ResourceId", valid_603123
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603124 = header.getOrDefault("X-Amz-Date")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Date", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Security-Token")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Security-Token", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Content-Sha256", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Algorithm")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Algorithm", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Signature")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Signature", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-SignedHeaders", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Credential")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Credential", valid_603130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603132: Call_ChangeTagsForResource_603119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_603132.validator(path, query, header, formData, body)
  let scheme = call_603132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603132.url(scheme.get, call_603132.host, call_603132.base,
                         call_603132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603132, url, valid)

proc call*(call_603133: Call_ChangeTagsForResource_603119; ResourceId: string;
          body: JsonNode; ResourceType: string = "healthcheck"): Recallable =
  ## changeTagsForResource
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   body: JObject (required)
  var path_603134 = newJObject()
  var body_603135 = newJObject()
  add(path_603134, "ResourceType", newJString(ResourceType))
  add(path_603134, "ResourceId", newJString(ResourceId))
  if body != nil:
    body_603135 = body
  result = call_603133.call(path_603134, nil, nil, nil, body_603135)

var changeTagsForResource* = Call_ChangeTagsForResource_603119(
    name: "changeTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ChangeTagsForResource_603120, base: "/",
    url: url_ChangeTagsForResource_603121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603091 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603093(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  assert "ResourceId" in path, "`ResourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "ResourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTagsForResource_603092(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceType` field"
  var valid_603107 = path.getOrDefault("ResourceType")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_603107 != nil:
    section.add "ResourceType", valid_603107
  var valid_603108 = path.getOrDefault("ResourceId")
  valid_603108 = validateParameter(valid_603108, JString, required = true,
                                 default = nil)
  if valid_603108 != nil:
    section.add "ResourceId", valid_603108
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603109 = header.getOrDefault("X-Amz-Date")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Date", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Security-Token")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Security-Token", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Content-Sha256", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Algorithm")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Algorithm", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Signature")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Signature", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-SignedHeaders", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Credential")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Credential", valid_603115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603116: Call_ListTagsForResource_603091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_603116.validator(path, query, header, formData, body)
  let scheme = call_603116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603116.url(scheme.get, call_603116.host, call_603116.base,
                         call_603116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603116, url, valid)

proc call*(call_603117: Call_ListTagsForResource_603091; ResourceId: string;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  var path_603118 = newJObject()
  add(path_603118, "ResourceType", newJString(ResourceType))
  add(path_603118, "ResourceId", newJString(ResourceId))
  result = call_603117.call(path_603118, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603091(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ListTagsForResource_603092, base: "/",
    url: url_ListTagsForResource_603093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHealthCheck_603153 = ref object of OpenApiRestCall_602466
proc url_CreateHealthCheck_603155(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHealthCheck_603154(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603156 = header.getOrDefault("X-Amz-Date")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Date", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Security-Token")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Security-Token", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Content-Sha256", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Algorithm")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Algorithm", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Signature")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Signature", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-SignedHeaders", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Credential")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Credential", valid_603162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603164: Call_CreateHealthCheck_603153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ## 
  let valid = call_603164.validator(path, query, header, formData, body)
  let scheme = call_603164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603164.url(scheme.get, call_603164.host, call_603164.base,
                         call_603164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603164, url, valid)

proc call*(call_603165: Call_CreateHealthCheck_603153; body: JsonNode): Recallable =
  ## createHealthCheck
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603166 = newJObject()
  if body != nil:
    body_603166 = body
  result = call_603165.call(nil, nil, nil, nil, body_603166)

var createHealthCheck* = Call_CreateHealthCheck_603153(name: "createHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_CreateHealthCheck_603154,
    base: "/", url: url_CreateHealthCheck_603155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHealthChecks_603136 = ref object of OpenApiRestCall_602466
proc url_ListHealthChecks_603138(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHealthChecks_603137(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_603139 = query.getOrDefault("marker")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "marker", valid_603139
  var valid_603140 = query.getOrDefault("maxitems")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "maxitems", valid_603140
  var valid_603141 = query.getOrDefault("Marker")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "Marker", valid_603141
  var valid_603142 = query.getOrDefault("MaxItems")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "MaxItems", valid_603142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603143 = header.getOrDefault("X-Amz-Date")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Date", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Security-Token")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Security-Token", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Content-Sha256", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Algorithm")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Algorithm", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Signature")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Signature", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-SignedHeaders", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Credential")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Credential", valid_603149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603150: Call_ListHealthChecks_603136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  let valid = call_603150.validator(path, query, header, formData, body)
  let scheme = call_603150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603150.url(scheme.get, call_603150.host, call_603150.base,
                         call_603150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603150, url, valid)

proc call*(call_603151: Call_ListHealthChecks_603136; marker: string = "";
          maxitems: string = ""; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listHealthChecks
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  ##   maxitems: string
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  var query_603152 = newJObject()
  add(query_603152, "marker", newJString(marker))
  add(query_603152, "maxitems", newJString(maxitems))
  add(query_603152, "Marker", newJString(Marker))
  add(query_603152, "MaxItems", newJString(MaxItems))
  result = call_603151.call(nil, query_603152, nil, nil, nil)

var listHealthChecks* = Call_ListHealthChecks_603136(name: "listHealthChecks",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_ListHealthChecks_603137,
    base: "/", url: url_ListHealthChecks_603138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHostedZone_603185 = ref object of OpenApiRestCall_602466
proc url_CreateHostedZone_603187(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHostedZone_603186(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603188 = header.getOrDefault("X-Amz-Date")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Date", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Security-Token")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Security-Token", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Content-Sha256", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Algorithm")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Algorithm", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Signature")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Signature", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-SignedHeaders", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Credential")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Credential", valid_603194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_CreateHostedZone_603185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603196, url, valid)

proc call*(call_603197: Call_CreateHostedZone_603185; body: JsonNode): Recallable =
  ## createHostedZone
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ##   body: JObject (required)
  var body_603198 = newJObject()
  if body != nil:
    body_603198 = body
  result = call_603197.call(nil, nil, nil, nil, body_603198)

var createHostedZone* = Call_CreateHostedZone_603185(name: "createHostedZone",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_CreateHostedZone_603186,
    base: "/", url: url_CreateHostedZone_603187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZones_603167 = ref object of OpenApiRestCall_602466
proc url_ListHostedZones_603169(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHostedZones_603168(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   delegationsetid: JString
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_603170 = query.getOrDefault("delegationsetid")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "delegationsetid", valid_603170
  var valid_603171 = query.getOrDefault("marker")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "marker", valid_603171
  var valid_603172 = query.getOrDefault("maxitems")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "maxitems", valid_603172
  var valid_603173 = query.getOrDefault("Marker")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "Marker", valid_603173
  var valid_603174 = query.getOrDefault("MaxItems")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "MaxItems", valid_603174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603175 = header.getOrDefault("X-Amz-Date")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Date", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Security-Token")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Security-Token", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Content-Sha256", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Algorithm")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Algorithm", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Signature")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Signature", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-SignedHeaders", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Credential")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Credential", valid_603181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603182: Call_ListHostedZones_603167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603182.validator(path, query, header, formData, body)
  let scheme = call_603182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603182.url(scheme.get, call_603182.host, call_603182.base,
                         call_603182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603182, url, valid)

proc call*(call_603183: Call_ListHostedZones_603167; delegationsetid: string = "";
          marker: string = ""; maxitems: string = ""; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listHostedZones
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ##   delegationsetid: string
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  var query_603184 = newJObject()
  add(query_603184, "delegationsetid", newJString(delegationsetid))
  add(query_603184, "marker", newJString(marker))
  add(query_603184, "maxitems", newJString(maxitems))
  add(query_603184, "Marker", newJString(Marker))
  add(query_603184, "MaxItems", newJString(MaxItems))
  result = call_603183.call(nil, query_603184, nil, nil, nil)

var listHostedZones* = Call_ListHostedZones_603167(name: "listHostedZones",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_ListHostedZones_603168,
    base: "/", url: url_ListHostedZones_603169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueryLoggingConfig_603215 = ref object of OpenApiRestCall_602466
proc url_CreateQueryLoggingConfig_603217(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateQueryLoggingConfig_603216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603218 = header.getOrDefault("X-Amz-Date")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Date", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Security-Token")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Security-Token", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Content-Sha256", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Algorithm")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Algorithm", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Signature")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Signature", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-SignedHeaders", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Credential")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Credential", valid_603224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_CreateQueryLoggingConfig_603215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_CreateQueryLoggingConfig_603215; body: JsonNode): Recallable =
  ## createQueryLoggingConfig
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ##   body: JObject (required)
  var body_603228 = newJObject()
  if body != nil:
    body_603228 = body
  result = call_603227.call(nil, nil, nil, nil, body_603228)

var createQueryLoggingConfig* = Call_CreateQueryLoggingConfig_603215(
    name: "createQueryLoggingConfig", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_CreateQueryLoggingConfig_603216, base: "/",
    url: url_CreateQueryLoggingConfig_603217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryLoggingConfigs_603199 = ref object of OpenApiRestCall_602466
proc url_ListQueryLoggingConfigs_603201(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListQueryLoggingConfigs_603200(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: JString
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: JString
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  section = newJObject()
  var valid_603202 = query.getOrDefault("nexttoken")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "nexttoken", valid_603202
  var valid_603203 = query.getOrDefault("maxresults")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "maxresults", valid_603203
  var valid_603204 = query.getOrDefault("hostedzoneid")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "hostedzoneid", valid_603204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603205 = header.getOrDefault("X-Amz-Date")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Date", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Content-Sha256", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Algorithm")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Algorithm", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Signature")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Signature", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Credential")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Credential", valid_603211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603212: Call_ListQueryLoggingConfigs_603199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_603212.validator(path, query, header, formData, body)
  let scheme = call_603212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603212.url(scheme.get, call_603212.host, call_603212.base,
                         call_603212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603212, url, valid)

proc call*(call_603213: Call_ListQueryLoggingConfigs_603199;
          nexttoken: string = ""; maxresults: string = ""; hostedzoneid: string = ""): Recallable =
  ## listQueryLoggingConfigs
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   nexttoken: string
  ##            : <p>(Optional) If the current AWS account has more than <code>MaxResults</code> query logging configurations, use <code>NextToken</code> to get the second and subsequent pages of results.</p> <p>For the first <code>ListQueryLoggingConfigs</code> request, omit this value.</p> <p>For the second and subsequent requests, get the value of <code>NextToken</code> from the previous response and specify that value for <code>NextToken</code> in the request.</p>
  ##   maxresults: string
  ##             : <p>(Optional) The maximum number of query logging configurations that you want Amazon Route 53 to return in response to the current request. If the current AWS account has more than <code>MaxResults</code> configurations, use the value of <a 
  ## href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListQueryLoggingConfigs.html#API_ListQueryLoggingConfigs_RequestSyntax">NextToken</a> in the response to get the next page of results.</p> <p>If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 100 configurations.</p>
  ##   hostedzoneid: string
  ##               : <p>(Optional) If you want to list the query logging configuration that is associated with a hosted zone, specify the ID in <code>HostedZoneId</code>. </p> <p>If you don't specify a hosted zone ID, <code>ListQueryLoggingConfigs</code> returns all of the configurations that are associated with the current AWS account.</p>
  var query_603214 = newJObject()
  add(query_603214, "nexttoken", newJString(nexttoken))
  add(query_603214, "maxresults", newJString(maxresults))
  add(query_603214, "hostedzoneid", newJString(hostedzoneid))
  result = call_603213.call(nil, query_603214, nil, nil, nil)

var listQueryLoggingConfigs* = Call_ListQueryLoggingConfigs_603199(
    name: "listQueryLoggingConfigs", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_ListQueryLoggingConfigs_603200, base: "/",
    url: url_ListQueryLoggingConfigs_603201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReusableDelegationSet_603244 = ref object of OpenApiRestCall_602466
proc url_CreateReusableDelegationSet_603246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateReusableDelegationSet_603245(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603247 = header.getOrDefault("X-Amz-Date")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Date", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Security-Token")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Security-Token", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Content-Sha256", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Algorithm")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Algorithm", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Signature")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Signature", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-SignedHeaders", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Credential")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Credential", valid_603253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603255: Call_CreateReusableDelegationSet_603244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ## 
  let valid = call_603255.validator(path, query, header, formData, body)
  let scheme = call_603255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603255.url(scheme.get, call_603255.host, call_603255.base,
                         call_603255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603255, url, valid)

proc call*(call_603256: Call_CreateReusableDelegationSet_603244; body: JsonNode): Recallable =
  ## createReusableDelegationSet
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603257 = newJObject()
  if body != nil:
    body_603257 = body
  result = call_603256.call(nil, nil, nil, nil, body_603257)

var createReusableDelegationSet* = Call_CreateReusableDelegationSet_603244(
    name: "createReusableDelegationSet", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_CreateReusableDelegationSet_603245, base: "/",
    url: url_CreateReusableDelegationSet_603246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReusableDelegationSets_603229 = ref object of OpenApiRestCall_602466
proc url_ListReusableDelegationSets_603231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListReusableDelegationSets_603230(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  ##   maxitems: JString
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  section = newJObject()
  var valid_603232 = query.getOrDefault("marker")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "marker", valid_603232
  var valid_603233 = query.getOrDefault("maxitems")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "maxitems", valid_603233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603234 = header.getOrDefault("X-Amz-Date")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Date", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Security-Token")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Security-Token", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Content-Sha256", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Algorithm")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Algorithm", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Signature")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Signature", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-SignedHeaders", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Credential")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Credential", valid_603240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603241: Call_ListReusableDelegationSets_603229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  let valid = call_603241.validator(path, query, header, formData, body)
  let scheme = call_603241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603241.url(scheme.get, call_603241.host, call_603241.base,
                         call_603241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603241, url, valid)

proc call*(call_603242: Call_ListReusableDelegationSets_603229;
          marker: string = ""; maxitems: string = ""): Recallable =
  ## listReusableDelegationSets
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  ##   maxitems: string
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  var query_603243 = newJObject()
  add(query_603243, "marker", newJString(marker))
  add(query_603243, "maxitems", newJString(maxitems))
  result = call_603242.call(nil, query_603243, nil, nil, nil)

var listReusableDelegationSets* = Call_ListReusableDelegationSets_603229(
    name: "listReusableDelegationSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_ListReusableDelegationSets_603230, base: "/",
    url: url_ListReusableDelegationSets_603231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicy_603258 = ref object of OpenApiRestCall_602466
proc url_CreateTrafficPolicy_603260(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrafficPolicy_603259(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603261 = header.getOrDefault("X-Amz-Date")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Date", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Security-Token")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Security-Token", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Content-Sha256", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Algorithm")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Algorithm", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Signature")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Signature", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-SignedHeaders", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Credential")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Credential", valid_603267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603269: Call_CreateTrafficPolicy_603258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ## 
  let valid = call_603269.validator(path, query, header, formData, body)
  let scheme = call_603269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603269.url(scheme.get, call_603269.host, call_603269.base,
                         call_603269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603269, url, valid)

proc call*(call_603270: Call_CreateTrafficPolicy_603258; body: JsonNode): Recallable =
  ## createTrafficPolicy
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ##   body: JObject (required)
  var body_603271 = newJObject()
  if body != nil:
    body_603271 = body
  result = call_603270.call(nil, nil, nil, nil, body_603271)

var createTrafficPolicy* = Call_CreateTrafficPolicy_603258(
    name: "createTrafficPolicy", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy",
    validator: validate_CreateTrafficPolicy_603259, base: "/",
    url: url_CreateTrafficPolicy_603260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyInstance_603272 = ref object of OpenApiRestCall_602466
proc url_CreateTrafficPolicyInstance_603274(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrafficPolicyInstance_603273(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603275 = header.getOrDefault("X-Amz-Date")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Date", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Security-Token")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Security-Token", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Content-Sha256", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Algorithm")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Algorithm", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Signature")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Signature", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-SignedHeaders", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Credential")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Credential", valid_603281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603283: Call_CreateTrafficPolicyInstance_603272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ## 
  let valid = call_603283.validator(path, query, header, formData, body)
  let scheme = call_603283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603283.url(scheme.get, call_603283.host, call_603283.base,
                         call_603283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603283, url, valid)

proc call*(call_603284: Call_CreateTrafficPolicyInstance_603272; body: JsonNode): Recallable =
  ## createTrafficPolicyInstance
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ##   body: JObject (required)
  var body_603285 = newJObject()
  if body != nil:
    body_603285 = body
  result = call_603284.call(nil, nil, nil, nil, body_603285)

var createTrafficPolicyInstance* = Call_CreateTrafficPolicyInstance_603272(
    name: "createTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstance",
    validator: validate_CreateTrafficPolicyInstance_603273, base: "/",
    url: url_CreateTrafficPolicyInstance_603274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyVersion_603286 = ref object of OpenApiRestCall_602466
proc url_CreateTrafficPolicyVersion_603288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateTrafficPolicyVersion_603287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603289 = path.getOrDefault("Id")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = nil)
  if valid_603289 != nil:
    section.add "Id", valid_603289
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603290 = header.getOrDefault("X-Amz-Date")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Date", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Security-Token")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Security-Token", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Content-Sha256", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Algorithm")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Algorithm", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Signature")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Signature", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-SignedHeaders", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Credential")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Credential", valid_603296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_CreateTrafficPolicyVersion_603286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603298, url, valid)

proc call*(call_603299: Call_CreateTrafficPolicyVersion_603286; Id: string;
          body: JsonNode): Recallable =
  ## createTrafficPolicyVersion
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ##   Id: string (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  ##   body: JObject (required)
  var path_603300 = newJObject()
  var body_603301 = newJObject()
  add(path_603300, "Id", newJString(Id))
  if body != nil:
    body_603301 = body
  result = call_603299.call(path_603300, nil, nil, nil, body_603301)

var createTrafficPolicyVersion* = Call_CreateTrafficPolicyVersion_603286(
    name: "createTrafficPolicyVersion", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy/{Id}",
    validator: validate_CreateTrafficPolicyVersion_603287, base: "/",
    url: url_CreateTrafficPolicyVersion_603288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCAssociationAuthorization_603319 = ref object of OpenApiRestCall_602466
proc url_CreateVPCAssociationAuthorization_603321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateVPCAssociationAuthorization_603320(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603322 = path.getOrDefault("Id")
  valid_603322 = validateParameter(valid_603322, JString, required = true,
                                 default = nil)
  if valid_603322 != nil:
    section.add "Id", valid_603322
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603323 = header.getOrDefault("X-Amz-Date")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Date", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Security-Token")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Security-Token", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Content-Sha256", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Algorithm")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Algorithm", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Signature")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Signature", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-SignedHeaders", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Credential")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Credential", valid_603329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603331: Call_CreateVPCAssociationAuthorization_603319;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  let valid = call_603331.validator(path, query, header, formData, body)
  let scheme = call_603331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603331.url(scheme.get, call_603331.host, call_603331.base,
                         call_603331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603331, url, valid)

proc call*(call_603332: Call_CreateVPCAssociationAuthorization_603319; Id: string;
          body: JsonNode): Recallable =
  ## createVPCAssociationAuthorization
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  ##   body: JObject (required)
  var path_603333 = newJObject()
  var body_603334 = newJObject()
  add(path_603333, "Id", newJString(Id))
  if body != nil:
    body_603334 = body
  result = call_603332.call(path_603333, nil, nil, nil, body_603334)

var createVPCAssociationAuthorization* = Call_CreateVPCAssociationAuthorization_603319(
    name: "createVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_CreateVPCAssociationAuthorization_603320, base: "/",
    url: url_CreateVPCAssociationAuthorization_603321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCAssociationAuthorizations_603302 = ref object of OpenApiRestCall_602466
proc url_ListVPCAssociationAuthorizations_603304(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/authorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListVPCAssociationAuthorizations_603303(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603305 = path.getOrDefault("Id")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = nil)
  if valid_603305 != nil:
    section.add "Id", valid_603305
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: JString
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  section = newJObject()
  var valid_603306 = query.getOrDefault("nexttoken")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "nexttoken", valid_603306
  var valid_603307 = query.getOrDefault("maxresults")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "maxresults", valid_603307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603308 = header.getOrDefault("X-Amz-Date")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Date", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Security-Token")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Security-Token", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Content-Sha256", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Algorithm")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Algorithm", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Signature")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Signature", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-SignedHeaders", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Credential")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Credential", valid_603314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603315: Call_ListVPCAssociationAuthorizations_603302;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  let valid = call_603315.validator(path, query, header, formData, body)
  let scheme = call_603315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603315.url(scheme.get, call_603315.host, call_603315.base,
                         call_603315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603315, url, valid)

proc call*(call_603316: Call_ListVPCAssociationAuthorizations_603302; Id: string;
          nexttoken: string = ""; maxresults: string = ""): Recallable =
  ## listVPCAssociationAuthorizations
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ##   nexttoken: string
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   Id: string (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  ##   maxresults: string
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  var path_603317 = newJObject()
  var query_603318 = newJObject()
  add(query_603318, "nexttoken", newJString(nexttoken))
  add(path_603317, "Id", newJString(Id))
  add(query_603318, "maxresults", newJString(maxresults))
  result = call_603316.call(path_603317, query_603318, nil, nil, nil)

var listVPCAssociationAuthorizations* = Call_ListVPCAssociationAuthorizations_603302(
    name: "listVPCAssociationAuthorizations", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_ListVPCAssociationAuthorizations_603303, base: "/",
    url: url_ListVPCAssociationAuthorizations_603304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHealthCheck_603349 = ref object of OpenApiRestCall_602466
proc url_UpdateHealthCheck_603351(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateHealthCheck_603350(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603352 = path.getOrDefault("HealthCheckId")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = nil)
  if valid_603352 != nil:
    section.add "HealthCheckId", valid_603352
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603353 = header.getOrDefault("X-Amz-Date")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Date", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Security-Token")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Security-Token", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Content-Sha256", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Algorithm")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Algorithm", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Signature")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Signature", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-SignedHeaders", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Credential")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Credential", valid_603359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603361: Call_UpdateHealthCheck_603349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_603361.validator(path, query, header, formData, body)
  let scheme = call_603361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603361.url(scheme.get, call_603361.host, call_603361.base,
                         call_603361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603361, url, valid)

proc call*(call_603362: Call_UpdateHealthCheck_603349; HealthCheckId: string;
          body: JsonNode): Recallable =
  ## updateHealthCheck
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   HealthCheckId: string (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  ##   body: JObject (required)
  var path_603363 = newJObject()
  var body_603364 = newJObject()
  add(path_603363, "HealthCheckId", newJString(HealthCheckId))
  if body != nil:
    body_603364 = body
  result = call_603362.call(path_603363, nil, nil, nil, body_603364)

var updateHealthCheck* = Call_UpdateHealthCheck_603349(name: "updateHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_UpdateHealthCheck_603350, base: "/",
    url: url_UpdateHealthCheck_603351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheck_603335 = ref object of OpenApiRestCall_602466
proc url_GetHealthCheck_603337(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetHealthCheck_603336(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a specified health check.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603338 = path.getOrDefault("HealthCheckId")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = nil)
  if valid_603338 != nil:
    section.add "HealthCheckId", valid_603338
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603339 = header.getOrDefault("X-Amz-Date")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Date", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Security-Token")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Security-Token", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Content-Sha256", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Algorithm")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Algorithm", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Signature")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Signature", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-SignedHeaders", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Credential")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Credential", valid_603345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603346: Call_GetHealthCheck_603335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified health check.
  ## 
  let valid = call_603346.validator(path, query, header, formData, body)
  let scheme = call_603346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603346.url(scheme.get, call_603346.host, call_603346.base,
                         call_603346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603346, url, valid)

proc call*(call_603347: Call_GetHealthCheck_603335; HealthCheckId: string): Recallable =
  ## getHealthCheck
  ## Gets information about a specified health check.
  ##   HealthCheckId: string (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  var path_603348 = newJObject()
  add(path_603348, "HealthCheckId", newJString(HealthCheckId))
  result = call_603347.call(path_603348, nil, nil, nil, nil)

var getHealthCheck* = Call_GetHealthCheck_603335(name: "getHealthCheck",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_GetHealthCheck_603336, base: "/", url: url_GetHealthCheck_603337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHealthCheck_603365 = ref object of OpenApiRestCall_602466
proc url_DeleteHealthCheck_603367(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteHealthCheck_603366(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : The ID of the health check that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603368 = path.getOrDefault("HealthCheckId")
  valid_603368 = validateParameter(valid_603368, JString, required = true,
                                 default = nil)
  if valid_603368 != nil:
    section.add "HealthCheckId", valid_603368
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603369 = header.getOrDefault("X-Amz-Date")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Date", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Security-Token")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Security-Token", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Content-Sha256", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Algorithm")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Algorithm", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Signature")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Signature", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-SignedHeaders", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Credential")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Credential", valid_603375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603376: Call_DeleteHealthCheck_603365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_603376.validator(path, query, header, formData, body)
  let scheme = call_603376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603376.url(scheme.get, call_603376.host, call_603376.base,
                         call_603376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603376, url, valid)

proc call*(call_603377: Call_DeleteHealthCheck_603365; HealthCheckId: string): Recallable =
  ## deleteHealthCheck
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ##   HealthCheckId: string (required)
  ##                : The ID of the health check that you want to delete.
  var path_603378 = newJObject()
  add(path_603378, "HealthCheckId", newJString(HealthCheckId))
  result = call_603377.call(path_603378, nil, nil, nil, nil)

var deleteHealthCheck* = Call_DeleteHealthCheck_603365(name: "deleteHealthCheck",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_DeleteHealthCheck_603366, base: "/",
    url: url_DeleteHealthCheck_603367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHostedZoneComment_603393 = ref object of OpenApiRestCall_602466
proc url_UpdateHostedZoneComment_603395(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateHostedZoneComment_603394(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603396 = path.getOrDefault("Id")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = nil)
  if valid_603396 != nil:
    section.add "Id", valid_603396
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Content-Sha256", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Algorithm")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Algorithm", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Signature")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Signature", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-SignedHeaders", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Credential")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Credential", valid_603403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603405: Call_UpdateHostedZoneComment_603393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified hosted zone.
  ## 
  let valid = call_603405.validator(path, query, header, formData, body)
  let scheme = call_603405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603405.url(scheme.get, call_603405.host, call_603405.base,
                         call_603405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603405, url, valid)

proc call*(call_603406: Call_UpdateHostedZoneComment_603393; Id: string;
          body: JsonNode): Recallable =
  ## updateHostedZoneComment
  ## Updates the comment for a specified hosted zone.
  ##   Id: string (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  ##   body: JObject (required)
  var path_603407 = newJObject()
  var body_603408 = newJObject()
  add(path_603407, "Id", newJString(Id))
  if body != nil:
    body_603408 = body
  result = call_603406.call(path_603407, nil, nil, nil, body_603408)

var updateHostedZoneComment* = Call_UpdateHostedZoneComment_603393(
    name: "updateHostedZoneComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}",
    validator: validate_UpdateHostedZoneComment_603394, base: "/",
    url: url_UpdateHostedZoneComment_603395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZone_603379 = ref object of OpenApiRestCall_602466
proc url_GetHostedZone_603381(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetHostedZone_603380(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603382 = path.getOrDefault("Id")
  valid_603382 = validateParameter(valid_603382, JString, required = true,
                                 default = nil)
  if valid_603382 != nil:
    section.add "Id", valid_603382
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603383 = header.getOrDefault("X-Amz-Date")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Date", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Security-Token")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Security-Token", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Content-Sha256", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Algorithm")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Algorithm", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Signature")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Signature", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-SignedHeaders", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Credential")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Credential", valid_603389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603390: Call_GetHostedZone_603379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  let valid = call_603390.validator(path, query, header, formData, body)
  let scheme = call_603390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603390.url(scheme.get, call_603390.host, call_603390.base,
                         call_603390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603390, url, valid)

proc call*(call_603391: Call_GetHostedZone_603379; Id: string): Recallable =
  ## getHostedZone
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get information about.
  var path_603392 = newJObject()
  add(path_603392, "Id", newJString(Id))
  result = call_603391.call(path_603392, nil, nil, nil, nil)

var getHostedZone* = Call_GetHostedZone_603379(name: "getHostedZone",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_GetHostedZone_603380,
    base: "/", url: url_GetHostedZone_603381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHostedZone_603409 = ref object of OpenApiRestCall_602466
proc url_DeleteHostedZone_603411(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteHostedZone_603410(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603412 = path.getOrDefault("Id")
  valid_603412 = validateParameter(valid_603412, JString, required = true,
                                 default = nil)
  if valid_603412 != nil:
    section.add "Id", valid_603412
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603413 = header.getOrDefault("X-Amz-Date")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Date", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Security-Token")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Security-Token", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Content-Sha256", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Algorithm")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Algorithm", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Signature")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Signature", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-SignedHeaders", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Credential")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Credential", valid_603419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603420: Call_DeleteHostedZone_603409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  let valid = call_603420.validator(path, query, header, formData, body)
  let scheme = call_603420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603420.url(scheme.get, call_603420.host, call_603420.base,
                         call_603420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603420, url, valid)

proc call*(call_603421: Call_DeleteHostedZone_603409; Id: string): Recallable =
  ## deleteHostedZone
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone you want to delete.
  var path_603422 = newJObject()
  add(path_603422, "Id", newJString(Id))
  result = call_603421.call(path_603422, nil, nil, nil, nil)

var deleteHostedZone* = Call_DeleteHostedZone_603409(name: "deleteHostedZone",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_DeleteHostedZone_603410,
    base: "/", url: url_DeleteHostedZone_603411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryLoggingConfig_603423 = ref object of OpenApiRestCall_602466
proc url_GetQueryLoggingConfig_603425(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetQueryLoggingConfig_603424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603426 = path.getOrDefault("Id")
  valid_603426 = validateParameter(valid_603426, JString, required = true,
                                 default = nil)
  if valid_603426 != nil:
    section.add "Id", valid_603426
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603427 = header.getOrDefault("X-Amz-Date")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Date", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Security-Token")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Security-Token", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Content-Sha256", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Algorithm")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Algorithm", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Signature")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Signature", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-SignedHeaders", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Credential")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Credential", valid_603433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603434: Call_GetQueryLoggingConfig_603423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  let valid = call_603434.validator(path, query, header, formData, body)
  let scheme = call_603434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603434.url(scheme.get, call_603434.host, call_603434.base,
                         call_603434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603434, url, valid)

proc call*(call_603435: Call_GetQueryLoggingConfig_603423; Id: string): Recallable =
  ## getQueryLoggingConfig
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  var path_603436 = newJObject()
  add(path_603436, "Id", newJString(Id))
  result = call_603435.call(path_603436, nil, nil, nil, nil)

var getQueryLoggingConfig* = Call_GetQueryLoggingConfig_603423(
    name: "getQueryLoggingConfig", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_GetQueryLoggingConfig_603424, base: "/",
    url: url_GetQueryLoggingConfig_603425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueryLoggingConfig_603437 = ref object of OpenApiRestCall_602466
proc url_DeleteQueryLoggingConfig_603439(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/queryloggingconfig/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteQueryLoggingConfig_603438(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration that you want to delete. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603440 = path.getOrDefault("Id")
  valid_603440 = validateParameter(valid_603440, JString, required = true,
                                 default = nil)
  if valid_603440 != nil:
    section.add "Id", valid_603440
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603441 = header.getOrDefault("X-Amz-Date")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Date", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Security-Token")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Security-Token", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Content-Sha256", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Algorithm")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Algorithm", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Signature")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Signature", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-SignedHeaders", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Credential")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Credential", valid_603447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603448: Call_DeleteQueryLoggingConfig_603437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  let valid = call_603448.validator(path, query, header, formData, body)
  let scheme = call_603448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603448.url(scheme.get, call_603448.host, call_603448.base,
                         call_603448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603448, url, valid)

proc call*(call_603449: Call_DeleteQueryLoggingConfig_603437; Id: string): Recallable =
  ## deleteQueryLoggingConfig
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration that you want to delete. 
  var path_603450 = newJObject()
  add(path_603450, "Id", newJString(Id))
  result = call_603449.call(path_603450, nil, nil, nil, nil)

var deleteQueryLoggingConfig* = Call_DeleteQueryLoggingConfig_603437(
    name: "deleteQueryLoggingConfig", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_DeleteQueryLoggingConfig_603438, base: "/",
    url: url_DeleteQueryLoggingConfig_603439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSet_603451 = ref object of OpenApiRestCall_602466
proc url_GetReusableDelegationSet_603453(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetReusableDelegationSet_603452(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603454 = path.getOrDefault("Id")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = nil)
  if valid_603454 != nil:
    section.add "Id", valid_603454
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603455 = header.getOrDefault("X-Amz-Date")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Date", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Security-Token")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Security-Token", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603462: Call_GetReusableDelegationSet_603451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  let valid = call_603462.validator(path, query, header, formData, body)
  let scheme = call_603462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603462.url(scheme.get, call_603462.host, call_603462.base,
                         call_603462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603462, url, valid)

proc call*(call_603463: Call_GetReusableDelegationSet_603451; Id: string): Recallable =
  ## getReusableDelegationSet
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  var path_603464 = newJObject()
  add(path_603464, "Id", newJString(Id))
  result = call_603463.call(path_603464, nil, nil, nil, nil)

var getReusableDelegationSet* = Call_GetReusableDelegationSet_603451(
    name: "getReusableDelegationSet", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_GetReusableDelegationSet_603452, base: "/",
    url: url_GetReusableDelegationSet_603453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReusableDelegationSet_603465 = ref object of OpenApiRestCall_602466
proc url_DeleteReusableDelegationSet_603467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/delegationset/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteReusableDelegationSet_603466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603468 = path.getOrDefault("Id")
  valid_603468 = validateParameter(valid_603468, JString, required = true,
                                 default = nil)
  if valid_603468 != nil:
    section.add "Id", valid_603468
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603469 = header.getOrDefault("X-Amz-Date")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Date", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Security-Token")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Security-Token", valid_603470
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
  if body != nil:
    result.add "body", body

proc call*(call_603476: Call_DeleteReusableDelegationSet_603465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  let valid = call_603476.validator(path, query, header, formData, body)
  let scheme = call_603476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603476.url(scheme.get, call_603476.host, call_603476.base,
                         call_603476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603476, url, valid)

proc call*(call_603477: Call_DeleteReusableDelegationSet_603465; Id: string): Recallable =
  ## deleteReusableDelegationSet
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  var path_603478 = newJObject()
  add(path_603478, "Id", newJString(Id))
  result = call_603477.call(path_603478, nil, nil, nil, nil)

var deleteReusableDelegationSet* = Call_DeleteReusableDelegationSet_603465(
    name: "deleteReusableDelegationSet", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_DeleteReusableDelegationSet_603466, base: "/",
    url: url_DeleteReusableDelegationSet_603467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyComment_603494 = ref object of OpenApiRestCall_602466
proc url_UpdateTrafficPolicyComment_603496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyComment_603495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  ##   Version: JInt (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603497 = path.getOrDefault("Id")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = nil)
  if valid_603497 != nil:
    section.add "Id", valid_603497
  var valid_603498 = path.getOrDefault("Version")
  valid_603498 = validateParameter(valid_603498, JInt, required = true, default = nil)
  if valid_603498 != nil:
    section.add "Version", valid_603498
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Security-Token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Security-Token", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Content-Sha256", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Algorithm")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Algorithm", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Signature")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Signature", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-SignedHeaders", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Credential")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Credential", valid_603505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603507: Call_UpdateTrafficPolicyComment_603494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified traffic policy version.
  ## 
  let valid = call_603507.validator(path, query, header, formData, body)
  let scheme = call_603507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603507.url(scheme.get, call_603507.host, call_603507.base,
                         call_603507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603507, url, valid)

proc call*(call_603508: Call_UpdateTrafficPolicyComment_603494; Id: string;
          Version: int; body: JsonNode): Recallable =
  ## updateTrafficPolicyComment
  ## Updates the comment for a specified traffic policy version.
  ##   Id: string (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  ##   Version: int (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   body: JObject (required)
  var path_603509 = newJObject()
  var body_603510 = newJObject()
  add(path_603509, "Id", newJString(Id))
  add(path_603509, "Version", newJInt(Version))
  if body != nil:
    body_603510 = body
  result = call_603508.call(path_603509, nil, nil, nil, body_603510)

var updateTrafficPolicyComment* = Call_UpdateTrafficPolicyComment_603494(
    name: "updateTrafficPolicyComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_UpdateTrafficPolicyComment_603495, base: "/",
    url: url_UpdateTrafficPolicyComment_603496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicy_603479 = ref object of OpenApiRestCall_602466
proc url_GetTrafficPolicy_603481(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetTrafficPolicy_603480(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about a specific traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to get information about.
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603482 = path.getOrDefault("Id")
  valid_603482 = validateParameter(valid_603482, JString, required = true,
                                 default = nil)
  if valid_603482 != nil:
    section.add "Id", valid_603482
  var valid_603483 = path.getOrDefault("Version")
  valid_603483 = validateParameter(valid_603483, JInt, required = true, default = nil)
  if valid_603483 != nil:
    section.add "Version", valid_603483
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603484 = header.getOrDefault("X-Amz-Date")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Date", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Security-Token")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Security-Token", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Content-Sha256", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Algorithm")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Algorithm", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Signature")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Signature", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-SignedHeaders", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Credential")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Credential", valid_603490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603491: Call_GetTrafficPolicy_603479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific traffic policy version.
  ## 
  let valid = call_603491.validator(path, query, header, formData, body)
  let scheme = call_603491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603491.url(scheme.get, call_603491.host, call_603491.base,
                         call_603491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603491, url, valid)

proc call*(call_603492: Call_GetTrafficPolicy_603479; Id: string; Version: int): Recallable =
  ## getTrafficPolicy
  ## Gets information about a specific traffic policy version.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to get information about.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to get information about.
  var path_603493 = newJObject()
  add(path_603493, "Id", newJString(Id))
  add(path_603493, "Version", newJInt(Version))
  result = call_603492.call(path_603493, nil, nil, nil, nil)

var getTrafficPolicy* = Call_GetTrafficPolicy_603479(name: "getTrafficPolicy",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_GetTrafficPolicy_603480, base: "/",
    url: url_GetTrafficPolicy_603481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicy_603511 = ref object of OpenApiRestCall_602466
proc url_DeleteTrafficPolicy_603513(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Version" in path, "`Version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicy/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteTrafficPolicy_603512(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to delete.
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603514 = path.getOrDefault("Id")
  valid_603514 = validateParameter(valid_603514, JString, required = true,
                                 default = nil)
  if valid_603514 != nil:
    section.add "Id", valid_603514
  var valid_603515 = path.getOrDefault("Version")
  valid_603515 = validateParameter(valid_603515, JInt, required = true, default = nil)
  if valid_603515 != nil:
    section.add "Version", valid_603515
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603516 = header.getOrDefault("X-Amz-Date")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Date", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Security-Token")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Security-Token", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Content-Sha256", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Algorithm")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Algorithm", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Signature")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Signature", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-SignedHeaders", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Credential")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Credential", valid_603522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603523: Call_DeleteTrafficPolicy_603511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a traffic policy.
  ## 
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603523, url, valid)

proc call*(call_603524: Call_DeleteTrafficPolicy_603511; Id: string; Version: int): Recallable =
  ## deleteTrafficPolicy
  ## Deletes a traffic policy.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to delete.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to delete.
  var path_603525 = newJObject()
  add(path_603525, "Id", newJString(Id))
  add(path_603525, "Version", newJInt(Version))
  result = call_603524.call(path_603525, nil, nil, nil, nil)

var deleteTrafficPolicy* = Call_DeleteTrafficPolicy_603511(
    name: "deleteTrafficPolicy", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_DeleteTrafficPolicy_603512, base: "/",
    url: url_DeleteTrafficPolicy_603513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyInstance_603540 = ref object of OpenApiRestCall_602466
proc url_UpdateTrafficPolicyInstance_603542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyInstance_603541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603543 = path.getOrDefault("Id")
  valid_603543 = validateParameter(valid_603543, JString, required = true,
                                 default = nil)
  if valid_603543 != nil:
    section.add "Id", valid_603543
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603544 = header.getOrDefault("X-Amz-Date")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Date", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Content-Sha256", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Algorithm")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Algorithm", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Signature")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Signature", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-SignedHeaders", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Credential")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Credential", valid_603550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603552: Call_UpdateTrafficPolicyInstance_603540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  let valid = call_603552.validator(path, query, header, formData, body)
  let scheme = call_603552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603552.url(scheme.get, call_603552.host, call_603552.base,
                         call_603552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603552, url, valid)

proc call*(call_603553: Call_UpdateTrafficPolicyInstance_603540; Id: string;
          body: JsonNode): Recallable =
  ## updateTrafficPolicyInstance
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to update.
  ##   body: JObject (required)
  var path_603554 = newJObject()
  var body_603555 = newJObject()
  add(path_603554, "Id", newJString(Id))
  if body != nil:
    body_603555 = body
  result = call_603553.call(path_603554, nil, nil, nil, body_603555)

var updateTrafficPolicyInstance* = Call_UpdateTrafficPolicyInstance_603540(
    name: "updateTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_UpdateTrafficPolicyInstance_603541, base: "/",
    url: url_UpdateTrafficPolicyInstance_603542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstance_603526 = ref object of OpenApiRestCall_602466
proc url_GetTrafficPolicyInstance_603528(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetTrafficPolicyInstance_603527(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603529 = path.getOrDefault("Id")
  valid_603529 = validateParameter(valid_603529, JString, required = true,
                                 default = nil)
  if valid_603529 != nil:
    section.add "Id", valid_603529
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603530 = header.getOrDefault("X-Amz-Date")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Date", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Security-Token")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Security-Token", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Content-Sha256", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Algorithm")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Algorithm", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Signature")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Signature", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-SignedHeaders", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Credential")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Credential", valid_603536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603537: Call_GetTrafficPolicyInstance_603526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_603537.validator(path, query, header, formData, body)
  let scheme = call_603537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603537.url(scheme.get, call_603537.host, call_603537.base,
                         call_603537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603537, url, valid)

proc call*(call_603538: Call_GetTrafficPolicyInstance_603526; Id: string): Recallable =
  ## getTrafficPolicyInstance
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  var path_603539 = newJObject()
  add(path_603539, "Id", newJString(Id))
  result = call_603538.call(path_603539, nil, nil, nil, nil)

var getTrafficPolicyInstance* = Call_GetTrafficPolicyInstance_603526(
    name: "getTrafficPolicyInstance", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_GetTrafficPolicyInstance_603527, base: "/",
    url: url_GetTrafficPolicyInstance_603528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicyInstance_603556 = ref object of OpenApiRestCall_602466
proc url_DeleteTrafficPolicyInstance_603558(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicyinstance/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteTrafficPolicyInstance_603557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603559 = path.getOrDefault("Id")
  valid_603559 = validateParameter(valid_603559, JString, required = true,
                                 default = nil)
  if valid_603559 != nil:
    section.add "Id", valid_603559
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603560 = header.getOrDefault("X-Amz-Date")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Date", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-Security-Token")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Security-Token", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Content-Sha256", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Algorithm")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Algorithm", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Signature")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Signature", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-SignedHeaders", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Credential")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Credential", valid_603566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603567: Call_DeleteTrafficPolicyInstance_603556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_603567.validator(path, query, header, formData, body)
  let scheme = call_603567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603567.url(scheme.get, call_603567.host, call_603567.base,
                         call_603567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603567, url, valid)

proc call*(call_603568: Call_DeleteTrafficPolicyInstance_603556; Id: string): Recallable =
  ## deleteTrafficPolicyInstance
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  var path_603569 = newJObject()
  add(path_603569, "Id", newJString(Id))
  result = call_603568.call(path_603569, nil, nil, nil, nil)

var deleteTrafficPolicyInstance* = Call_DeleteTrafficPolicyInstance_603556(
    name: "deleteTrafficPolicyInstance", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_DeleteTrafficPolicyInstance_603557, base: "/",
    url: url_DeleteTrafficPolicyInstance_603558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCAssociationAuthorization_603570 = ref object of OpenApiRestCall_602466
proc url_DeleteVPCAssociationAuthorization_603572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/deauthorizevpcassociation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteVPCAssociationAuthorization_603571(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603573 = path.getOrDefault("Id")
  valid_603573 = validateParameter(valid_603573, JString, required = true,
                                 default = nil)
  if valid_603573 != nil:
    section.add "Id", valid_603573
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603574 = header.getOrDefault("X-Amz-Date")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Date", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Security-Token")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Security-Token", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Content-Sha256", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Algorithm")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Algorithm", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Signature")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Signature", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-SignedHeaders", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Credential")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Credential", valid_603580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603582: Call_DeleteVPCAssociationAuthorization_603570;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  let valid = call_603582.validator(path, query, header, formData, body)
  let scheme = call_603582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603582.url(scheme.get, call_603582.host, call_603582.base,
                         call_603582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603582, url, valid)

proc call*(call_603583: Call_DeleteVPCAssociationAuthorization_603570; Id: string;
          body: JsonNode): Recallable =
  ## deleteVPCAssociationAuthorization
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ##   Id: string (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  ##   body: JObject (required)
  var path_603584 = newJObject()
  var body_603585 = newJObject()
  add(path_603584, "Id", newJString(Id))
  if body != nil:
    body_603585 = body
  result = call_603583.call(path_603584, nil, nil, nil, body_603585)

var deleteVPCAssociationAuthorization* = Call_DeleteVPCAssociationAuthorization_603570(
    name: "deleteVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/deauthorizevpcassociation",
    validator: validate_DeleteVPCAssociationAuthorization_603571, base: "/",
    url: url_DeleteVPCAssociationAuthorization_603572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateVPCFromHostedZone_603586 = ref object of OpenApiRestCall_602466
proc url_DisassociateVPCFromHostedZone_603588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/disassociatevpc")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DisassociateVPCFromHostedZone_603587(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603589 = path.getOrDefault("Id")
  valid_603589 = validateParameter(valid_603589, JString, required = true,
                                 default = nil)
  if valid_603589 != nil:
    section.add "Id", valid_603589
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603590 = header.getOrDefault("X-Amz-Date")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Date", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Security-Token")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Security-Token", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Content-Sha256", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Algorithm")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Algorithm", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Signature")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Signature", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-SignedHeaders", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Credential")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Credential", valid_603596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603598: Call_DisassociateVPCFromHostedZone_603586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  let valid = call_603598.validator(path, query, header, formData, body)
  let scheme = call_603598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603598.url(scheme.get, call_603598.host, call_603598.base,
                         call_603598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603598, url, valid)

proc call*(call_603599: Call_DisassociateVPCFromHostedZone_603586; Id: string;
          body: JsonNode): Recallable =
  ## disassociateVPCFromHostedZone
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  ##   body: JObject (required)
  var path_603600 = newJObject()
  var body_603601 = newJObject()
  add(path_603600, "Id", newJString(Id))
  if body != nil:
    body_603601 = body
  result = call_603599.call(path_603600, nil, nil, nil, body_603601)

var disassociateVPCFromHostedZone* = Call_DisassociateVPCFromHostedZone_603586(
    name: "disassociateVPCFromHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/disassociatevpc",
    validator: validate_DisassociateVPCFromHostedZone_603587, base: "/",
    url: url_DisassociateVPCFromHostedZone_603588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountLimit_603602 = ref object of OpenApiRestCall_602466
proc url_GetAccountLimit_603604(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/accountlimit/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetAccountLimit_603603(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Type` field"
  var valid_603605 = path.getOrDefault("Type")
  valid_603605 = validateParameter(valid_603605, JString, required = true, default = newJString(
      "MAX_HEALTH_CHECKS_BY_OWNER"))
  if valid_603605 != nil:
    section.add "Type", valid_603605
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603606 = header.getOrDefault("X-Amz-Date")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Date", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Security-Token")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Security-Token", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Content-Sha256", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Algorithm")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Algorithm", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Signature")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Signature", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-SignedHeaders", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Credential")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Credential", valid_603612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603613: Call_GetAccountLimit_603602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  let valid = call_603613.validator(path, query, header, formData, body)
  let scheme = call_603613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603613.url(scheme.get, call_603613.host, call_603613.base,
                         call_603613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603613, url, valid)

proc call*(call_603614: Call_GetAccountLimit_603602;
          Type: string = "MAX_HEALTH_CHECKS_BY_OWNER"): Recallable =
  ## getAccountLimit
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  var path_603615 = newJObject()
  add(path_603615, "Type", newJString(Type))
  result = call_603614.call(path_603615, nil, nil, nil, nil)

var getAccountLimit* = Call_GetAccountLimit_603602(name: "getAccountLimit",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/accountlimit/{Type}", validator: validate_GetAccountLimit_603603,
    base: "/", url: url_GetAccountLimit_603604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChange_603616 = ref object of OpenApiRestCall_602466
proc url_GetChange_603618(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/change/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetChange_603617(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603619 = path.getOrDefault("Id")
  valid_603619 = validateParameter(valid_603619, JString, required = true,
                                 default = nil)
  if valid_603619 != nil:
    section.add "Id", valid_603619
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603620 = header.getOrDefault("X-Amz-Date")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Date", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Security-Token")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Security-Token", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Content-Sha256", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Algorithm")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Algorithm", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Signature")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Signature", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-SignedHeaders", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Credential")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Credential", valid_603626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603627: Call_GetChange_603616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  let valid = call_603627.validator(path, query, header, formData, body)
  let scheme = call_603627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603627.url(scheme.get, call_603627.host, call_603627.base,
                         call_603627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603627, url, valid)

proc call*(call_603628: Call_GetChange_603616; Id: string): Recallable =
  ## getChange
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  var path_603629 = newJObject()
  add(path_603629, "Id", newJString(Id))
  result = call_603628.call(path_603629, nil, nil, nil, nil)

var getChange* = Call_GetChange_603616(name: "getChange", meth: HttpMethod.HttpGet,
                                    host: "route53.amazonaws.com",
                                    route: "/2013-04-01/change/{Id}",
                                    validator: validate_GetChange_603617,
                                    base: "/", url: url_GetChange_603618,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckerIpRanges_603630 = ref object of OpenApiRestCall_602466
proc url_GetCheckerIpRanges_603632(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckerIpRanges_603631(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603633 = header.getOrDefault("X-Amz-Date")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Date", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Security-Token")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Security-Token", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Content-Sha256", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Algorithm")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Algorithm", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Signature")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Signature", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-SignedHeaders", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Credential")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Credential", valid_603639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603640: Call_GetCheckerIpRanges_603630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_603640.validator(path, query, header, formData, body)
  let scheme = call_603640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603640.url(scheme.get, call_603640.host, call_603640.base,
                         call_603640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603640, url, valid)

proc call*(call_603641: Call_GetCheckerIpRanges_603630): Recallable =
  ## getCheckerIpRanges
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  result = call_603641.call(nil, nil, nil, nil, nil)

var getCheckerIpRanges* = Call_GetCheckerIpRanges_603630(
    name: "getCheckerIpRanges", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/checkeripranges",
    validator: validate_GetCheckerIpRanges_603631, base: "/",
    url: url_GetCheckerIpRanges_603632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGeoLocation_603642 = ref object of OpenApiRestCall_602466
proc url_GetGeoLocation_603644(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGeoLocation_603643(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   continentcode: JString
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: JString
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: JString
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  section = newJObject()
  var valid_603645 = query.getOrDefault("continentcode")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "continentcode", valid_603645
  var valid_603646 = query.getOrDefault("countrycode")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "countrycode", valid_603646
  var valid_603647 = query.getOrDefault("subdivisioncode")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "subdivisioncode", valid_603647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603648 = header.getOrDefault("X-Amz-Date")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Date", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Security-Token")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Security-Token", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Content-Sha256", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Algorithm")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Algorithm", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Signature")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Signature", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-SignedHeaders", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Credential")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Credential", valid_603654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603655: Call_GetGeoLocation_603642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  let valid = call_603655.validator(path, query, header, formData, body)
  let scheme = call_603655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603655.url(scheme.get, call_603655.host, call_603655.base,
                         call_603655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603655, url, valid)

proc call*(call_603656: Call_GetGeoLocation_603642; continentcode: string = "";
          countrycode: string = ""; subdivisioncode: string = ""): Recallable =
  ## getGeoLocation
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ##   continentcode: string
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: string
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: string
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  var query_603657 = newJObject()
  add(query_603657, "continentcode", newJString(continentcode))
  add(query_603657, "countrycode", newJString(countrycode))
  add(query_603657, "subdivisioncode", newJString(subdivisioncode))
  result = call_603656.call(nil, query_603657, nil, nil, nil)

var getGeoLocation* = Call_GetGeoLocation_603642(name: "getGeoLocation",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocation", validator: validate_GetGeoLocation_603643,
    base: "/", url: url_GetGeoLocation_603644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckCount_603658 = ref object of OpenApiRestCall_602466
proc url_GetHealthCheckCount_603660(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetHealthCheckCount_603659(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the number of health checks that are associated with the current AWS account.
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603661 = header.getOrDefault("X-Amz-Date")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Date", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Security-Token")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Security-Token", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Content-Sha256", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Algorithm")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Algorithm", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Signature")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Signature", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-SignedHeaders", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Credential")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Credential", valid_603667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603668: Call_GetHealthCheckCount_603658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of health checks that are associated with the current AWS account.
  ## 
  let valid = call_603668.validator(path, query, header, formData, body)
  let scheme = call_603668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603668.url(scheme.get, call_603668.host, call_603668.base,
                         call_603668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603668, url, valid)

proc call*(call_603669: Call_GetHealthCheckCount_603658): Recallable =
  ## getHealthCheckCount
  ## Retrieves the number of health checks that are associated with the current AWS account.
  result = call_603669.call(nil, nil, nil, nil, nil)

var getHealthCheckCount* = Call_GetHealthCheckCount_603658(
    name: "getHealthCheckCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/healthcheckcount",
    validator: validate_GetHealthCheckCount_603659, base: "/",
    url: url_GetHealthCheckCount_603660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckLastFailureReason_603670 = ref object of OpenApiRestCall_602466
proc url_GetHealthCheckLastFailureReason_603672(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/lastfailurereason")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetHealthCheckLastFailureReason_603671(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603673 = path.getOrDefault("HealthCheckId")
  valid_603673 = validateParameter(valid_603673, JString, required = true,
                                 default = nil)
  if valid_603673 != nil:
    section.add "HealthCheckId", valid_603673
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603674 = header.getOrDefault("X-Amz-Date")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Date", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Security-Token")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Security-Token", valid_603675
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
  if body != nil:
    result.add "body", body

proc call*(call_603681: Call_GetHealthCheckLastFailureReason_603670;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  let valid = call_603681.validator(path, query, header, formData, body)
  let scheme = call_603681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603681.url(scheme.get, call_603681.host, call_603681.base,
                         call_603681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603681, url, valid)

proc call*(call_603682: Call_GetHealthCheckLastFailureReason_603670;
          HealthCheckId: string): Recallable =
  ## getHealthCheckLastFailureReason
  ## Gets the reason that a specified health check failed most recently.
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  var path_603683 = newJObject()
  add(path_603683, "HealthCheckId", newJString(HealthCheckId))
  result = call_603682.call(path_603683, nil, nil, nil, nil)

var getHealthCheckLastFailureReason* = Call_GetHealthCheckLastFailureReason_603670(
    name: "getHealthCheckLastFailureReason", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/lastfailurereason",
    validator: validate_GetHealthCheckLastFailureReason_603671, base: "/",
    url: url_GetHealthCheckLastFailureReason_603672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckStatus_603684 = ref object of OpenApiRestCall_602466
proc url_GetHealthCheckStatus_603686(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HealthCheckId" in path, "`HealthCheckId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/healthcheck/"),
               (kind: VariableSegment, value: "HealthCheckId"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetHealthCheckStatus_603685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets status of a specified health check. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HealthCheckId: JString (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `HealthCheckId` field"
  var valid_603687 = path.getOrDefault("HealthCheckId")
  valid_603687 = validateParameter(valid_603687, JString, required = true,
                                 default = nil)
  if valid_603687 != nil:
    section.add "HealthCheckId", valid_603687
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Content-Sha256", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Algorithm")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Algorithm", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Signature")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Signature", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-SignedHeaders", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Credential")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Credential", valid_603694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603695: Call_GetHealthCheckStatus_603684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status of a specified health check. 
  ## 
  let valid = call_603695.validator(path, query, header, formData, body)
  let scheme = call_603695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603695.url(scheme.get, call_603695.host, call_603695.base,
                         call_603695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603695, url, valid)

proc call*(call_603696: Call_GetHealthCheckStatus_603684; HealthCheckId: string): Recallable =
  ## getHealthCheckStatus
  ## Gets status of a specified health check. 
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  var path_603697 = newJObject()
  add(path_603697, "HealthCheckId", newJString(HealthCheckId))
  result = call_603696.call(path_603697, nil, nil, nil, nil)

var getHealthCheckStatus* = Call_GetHealthCheckStatus_603684(
    name: "getHealthCheckStatus", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/status",
    validator: validate_GetHealthCheckStatus_603685, base: "/",
    url: url_GetHealthCheckStatus_603686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneCount_603698 = ref object of OpenApiRestCall_602466
proc url_GetHostedZoneCount_603700(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetHostedZoneCount_603699(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603701 = header.getOrDefault("X-Amz-Date")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Date", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Security-Token")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Security-Token", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Content-Sha256", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Algorithm")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Algorithm", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Signature")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Signature", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-SignedHeaders", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Credential")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Credential", valid_603707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603708: Call_GetHostedZoneCount_603698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  ## 
  let valid = call_603708.validator(path, query, header, formData, body)
  let scheme = call_603708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603708.url(scheme.get, call_603708.host, call_603708.base,
                         call_603708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603708, url, valid)

proc call*(call_603709: Call_GetHostedZoneCount_603698): Recallable =
  ## getHostedZoneCount
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  result = call_603709.call(nil, nil, nil, nil, nil)

var getHostedZoneCount* = Call_GetHostedZoneCount_603698(
    name: "getHostedZoneCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonecount",
    validator: validate_GetHostedZoneCount_603699, base: "/",
    url: url_GetHostedZoneCount_603700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneLimit_603710 = ref object of OpenApiRestCall_602466
proc url_GetHostedZoneLimit_603712(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzonelimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetHostedZoneLimit_603711(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603713 = path.getOrDefault("Id")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "Id", valid_603713
  var valid_603714 = path.getOrDefault("Type")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = newJString("MAX_RRSETS_BY_ZONE"))
  if valid_603714 != nil:
    section.add "Type", valid_603714
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603715 = header.getOrDefault("X-Amz-Date")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Date", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Security-Token")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Security-Token", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Content-Sha256", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Algorithm")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Algorithm", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Signature")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Signature", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-SignedHeaders", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Credential")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Credential", valid_603721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603722: Call_GetHostedZoneLimit_603710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_603722.validator(path, query, header, formData, body)
  let scheme = call_603722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603722.url(scheme.get, call_603722.host, call_603722.base,
                         call_603722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603722, url, valid)

proc call*(call_603723: Call_GetHostedZoneLimit_603710; Id: string;
          Type: string = "MAX_RRSETS_BY_ZONE"): Recallable =
  ## getHostedZoneLimit
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  var path_603724 = newJObject()
  add(path_603724, "Id", newJString(Id))
  add(path_603724, "Type", newJString(Type))
  result = call_603723.call(path_603724, nil, nil, nil, nil)

var getHostedZoneLimit* = Call_GetHostedZoneLimit_603710(
    name: "getHostedZoneLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzonelimit/{Id}/{Type}",
    validator: validate_GetHostedZoneLimit_603711, base: "/",
    url: url_GetHostedZoneLimit_603712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSetLimit_603725 = ref object of OpenApiRestCall_602466
proc url_GetReusableDelegationSetLimit_603727(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  assert "Type" in path, "`Type` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2013-04-01/reusabledelegationsetlimit/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetReusableDelegationSetLimit_603726(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  ##   Type: JString (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603728 = path.getOrDefault("Id")
  valid_603728 = validateParameter(valid_603728, JString, required = true,
                                 default = nil)
  if valid_603728 != nil:
    section.add "Id", valid_603728
  var valid_603729 = path.getOrDefault("Type")
  valid_603729 = validateParameter(valid_603729, JString, required = true, default = newJString(
      "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"))
  if valid_603729 != nil:
    section.add "Type", valid_603729
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603730 = header.getOrDefault("X-Amz-Date")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Date", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Security-Token")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Security-Token", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Content-Sha256", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Algorithm")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Algorithm", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Signature")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Signature", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-SignedHeaders", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Credential")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Credential", valid_603736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603737: Call_GetReusableDelegationSetLimit_603725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_603737.validator(path, query, header, formData, body)
  let scheme = call_603737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603737.url(scheme.get, call_603737.host, call_603737.base,
                         call_603737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603737, url, valid)

proc call*(call_603738: Call_GetReusableDelegationSetLimit_603725; Id: string;
          Type: string = "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"): Recallable =
  ## getReusableDelegationSetLimit
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  ##   Type: string (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  var path_603739 = newJObject()
  add(path_603739, "Id", newJString(Id))
  add(path_603739, "Type", newJString(Type))
  result = call_603738.call(path_603739, nil, nil, nil, nil)

var getReusableDelegationSetLimit* = Call_GetReusableDelegationSetLimit_603725(
    name: "getReusableDelegationSetLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/reusabledelegationsetlimit/{Id}/{Type}",
    validator: validate_GetReusableDelegationSetLimit_603726, base: "/",
    url: url_GetReusableDelegationSetLimit_603727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstanceCount_603740 = ref object of OpenApiRestCall_602466
proc url_GetTrafficPolicyInstanceCount_603742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTrafficPolicyInstanceCount_603741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
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
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603743 = header.getOrDefault("X-Amz-Date")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Date", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Security-Token")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Security-Token", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Content-Sha256", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Algorithm")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Algorithm", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Signature")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Signature", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-SignedHeaders", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Credential")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Credential", valid_603749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603750: Call_GetTrafficPolicyInstanceCount_603740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  ## 
  let valid = call_603750.validator(path, query, header, formData, body)
  let scheme = call_603750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603750.url(scheme.get, call_603750.host, call_603750.base,
                         call_603750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603750, url, valid)

proc call*(call_603751: Call_GetTrafficPolicyInstanceCount_603740): Recallable =
  ## getTrafficPolicyInstanceCount
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  result = call_603751.call(nil, nil, nil, nil, nil)

var getTrafficPolicyInstanceCount* = Call_GetTrafficPolicyInstanceCount_603740(
    name: "getTrafficPolicyInstanceCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstancecount",
    validator: validate_GetTrafficPolicyInstanceCount_603741, base: "/",
    url: url_GetTrafficPolicyInstanceCount_603742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGeoLocations_603752 = ref object of OpenApiRestCall_602466
proc url_ListGeoLocations_603754(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGeoLocations_603753(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   startcountrycode: JString
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: JString
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  ##   startcontinentcode: JString
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  section = newJObject()
  var valid_603755 = query.getOrDefault("startcountrycode")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "startcountrycode", valid_603755
  var valid_603756 = query.getOrDefault("startsubdivisioncode")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "startsubdivisioncode", valid_603756
  var valid_603757 = query.getOrDefault("maxitems")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "maxitems", valid_603757
  var valid_603758 = query.getOrDefault("startcontinentcode")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "startcontinentcode", valid_603758
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603759 = header.getOrDefault("X-Amz-Date")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Date", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Security-Token")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Security-Token", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Content-Sha256", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Algorithm")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Algorithm", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Signature")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Signature", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-SignedHeaders", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Credential")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Credential", valid_603765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603766: Call_ListGeoLocations_603752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  let valid = call_603766.validator(path, query, header, formData, body)
  let scheme = call_603766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603766.url(scheme.get, call_603766.host, call_603766.base,
                         call_603766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603766, url, valid)

proc call*(call_603767: Call_ListGeoLocations_603752;
          startcountrycode: string = ""; startsubdivisioncode: string = "";
          maxitems: string = ""; startcontinentcode: string = ""): Recallable =
  ## listGeoLocations
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ##   startcountrycode: string
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: string
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  ##   startcontinentcode: string
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  var query_603768 = newJObject()
  add(query_603768, "startcountrycode", newJString(startcountrycode))
  add(query_603768, "startsubdivisioncode", newJString(startsubdivisioncode))
  add(query_603768, "maxitems", newJString(maxitems))
  add(query_603768, "startcontinentcode", newJString(startcontinentcode))
  result = call_603767.call(nil, query_603768, nil, nil, nil)

var listGeoLocations* = Call_ListGeoLocations_603752(name: "listGeoLocations",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocations", validator: validate_ListGeoLocations_603753,
    base: "/", url: url_ListGeoLocations_603754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZonesByName_603769 = ref object of OpenApiRestCall_602466
proc url_ListHostedZonesByName_603771(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHostedZonesByName_603770(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dnsname: JString
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: JString
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: JString
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  section = newJObject()
  var valid_603772 = query.getOrDefault("dnsname")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "dnsname", valid_603772
  var valid_603773 = query.getOrDefault("maxitems")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "maxitems", valid_603773
  var valid_603774 = query.getOrDefault("hostedzoneid")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "hostedzoneid", valid_603774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603775 = header.getOrDefault("X-Amz-Date")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Date", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Security-Token")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Security-Token", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Content-Sha256", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Algorithm")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Algorithm", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Signature")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Signature", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-SignedHeaders", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Credential")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Credential", valid_603781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603782: Call_ListHostedZonesByName_603769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  let valid = call_603782.validator(path, query, header, formData, body)
  let scheme = call_603782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603782.url(scheme.get, call_603782.host, call_603782.base,
                         call_603782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603782, url, valid)

proc call*(call_603783: Call_ListHostedZonesByName_603769; dnsname: string = "";
          maxitems: string = ""; hostedzoneid: string = ""): Recallable =
  ## listHostedZonesByName
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ##   dnsname: string
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: string
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: string
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  var query_603784 = newJObject()
  add(query_603784, "dnsname", newJString(dnsname))
  add(query_603784, "maxitems", newJString(maxitems))
  add(query_603784, "hostedzoneid", newJString(hostedzoneid))
  result = call_603783.call(nil, query_603784, nil, nil, nil)

var listHostedZonesByName* = Call_ListHostedZonesByName_603769(
    name: "listHostedZonesByName", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonesbyname",
    validator: validate_ListHostedZonesByName_603770, base: "/",
    url: url_ListHostedZonesByName_603771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceRecordSets_603785 = ref object of OpenApiRestCall_602466
proc url_ListResourceRecordSets_603787(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/hostedzone/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/rrset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListResourceRecordSets_603786(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603788 = path.getOrDefault("Id")
  valid_603788 = validateParameter(valid_603788, JString, required = true,
                                 default = nil)
  if valid_603788 != nil:
    section.add "Id", valid_603788
  result.add "path", section
  ## parameters in `query` object:
  ##   StartRecordIdentifier: JString
  ##                        : Pagination token
  ##   type: JString
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   identifier: JString
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  ##   StartRecordType: JString
  ##                  : Pagination token
  ##   maxitems: JString
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: JString
  ##                  : Pagination token
  ##   name: JString
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: JString
  ##           : Pagination limit
  section = newJObject()
  var valid_603789 = query.getOrDefault("StartRecordIdentifier")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "StartRecordIdentifier", valid_603789
  var valid_603790 = query.getOrDefault("type")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603790 != nil:
    section.add "type", valid_603790
  var valid_603791 = query.getOrDefault("identifier")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "identifier", valid_603791
  var valid_603792 = query.getOrDefault("StartRecordType")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "StartRecordType", valid_603792
  var valid_603793 = query.getOrDefault("maxitems")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "maxitems", valid_603793
  var valid_603794 = query.getOrDefault("StartRecordName")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "StartRecordName", valid_603794
  var valid_603795 = query.getOrDefault("name")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "name", valid_603795
  var valid_603796 = query.getOrDefault("MaxItems")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "MaxItems", valid_603796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603797 = header.getOrDefault("X-Amz-Date")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Date", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Security-Token")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Security-Token", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Content-Sha256", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Algorithm")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Algorithm", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Signature")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Signature", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-SignedHeaders", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Credential")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Credential", valid_603803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603804: Call_ListResourceRecordSets_603785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  let valid = call_603804.validator(path, query, header, formData, body)
  let scheme = call_603804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603804.url(scheme.get, call_603804.host, call_603804.base,
                         call_603804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603804, url, valid)

proc call*(call_603805: Call_ListResourceRecordSets_603785; Id: string;
          StartRecordIdentifier: string = ""; `type`: string = "SOA";
          identifier: string = ""; StartRecordType: string = ""; maxitems: string = "";
          StartRecordName: string = ""; name: string = ""; MaxItems: string = ""): Recallable =
  ## listResourceRecordSets
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  ##   StartRecordIdentifier: string
  ##                        : Pagination token
  ##   type: string
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   identifier: string
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  ##   StartRecordType: string
  ##                  : Pagination token
  ##   maxitems: string
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: string
  ##                  : Pagination token
  ##   name: string
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: string
  ##           : Pagination limit
  var path_603806 = newJObject()
  var query_603807 = newJObject()
  add(path_603806, "Id", newJString(Id))
  add(query_603807, "StartRecordIdentifier", newJString(StartRecordIdentifier))
  add(query_603807, "type", newJString(`type`))
  add(query_603807, "identifier", newJString(identifier))
  add(query_603807, "StartRecordType", newJString(StartRecordType))
  add(query_603807, "maxitems", newJString(maxitems))
  add(query_603807, "StartRecordName", newJString(StartRecordName))
  add(query_603807, "name", newJString(name))
  add(query_603807, "MaxItems", newJString(MaxItems))
  result = call_603805.call(path_603806, query_603807, nil, nil, nil)

var listResourceRecordSets* = Call_ListResourceRecordSets_603785(
    name: "listResourceRecordSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset",
    validator: validate_ListResourceRecordSets_603786, base: "/",
    url: url_ListResourceRecordSets_603787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResources_603808 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResources_603810(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceType" in path, "`ResourceType` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/tags/"),
               (kind: VariableSegment, value: "ResourceType")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTagsForResources_603809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceType` field"
  var valid_603811 = path.getOrDefault("ResourceType")
  valid_603811 = validateParameter(valid_603811, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_603811 != nil:
    section.add "ResourceType", valid_603811
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603812 = header.getOrDefault("X-Amz-Date")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Date", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Security-Token")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Security-Token", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Content-Sha256", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Algorithm")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Algorithm", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Signature")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Signature", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-SignedHeaders", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Credential")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Credential", valid_603818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603820: Call_ListTagsForResources_603808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_603820.validator(path, query, header, formData, body)
  let scheme = call_603820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603820.url(scheme.get, call_603820.host, call_603820.base,
                         call_603820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603820, url, valid)

proc call*(call_603821: Call_ListTagsForResources_603808; body: JsonNode;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResources
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_603822 = newJObject()
  var body_603823 = newJObject()
  add(path_603822, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_603823 = body
  result = call_603821.call(path_603822, nil, nil, nil, body_603823)

var listTagsForResources* = Call_ListTagsForResources_603808(
    name: "listTagsForResources", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/tags/{ResourceType}",
    validator: validate_ListTagsForResources_603809, base: "/",
    url: url_ListTagsForResources_603810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicies_603824 = ref object of OpenApiRestCall_602466
proc url_ListTrafficPolicies_603826(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrafficPolicies_603825(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyid: JString
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  section = newJObject()
  var valid_603827 = query.getOrDefault("trafficpolicyid")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "trafficpolicyid", valid_603827
  var valid_603828 = query.getOrDefault("maxitems")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "maxitems", valid_603828
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603829 = header.getOrDefault("X-Amz-Date")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Date", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Security-Token")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Security-Token", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Content-Sha256", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Algorithm")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Algorithm", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Signature")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Signature", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-SignedHeaders", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Credential")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Credential", valid_603835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603836: Call_ListTrafficPolicies_603824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  let valid = call_603836.validator(path, query, header, formData, body)
  let scheme = call_603836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603836.url(scheme.get, call_603836.host, call_603836.base,
                         call_603836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603836, url, valid)

proc call*(call_603837: Call_ListTrafficPolicies_603824;
          trafficpolicyid: string = ""; maxitems: string = ""): Recallable =
  ## listTrafficPolicies
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ##   trafficpolicyid: string
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  var query_603838 = newJObject()
  add(query_603838, "trafficpolicyid", newJString(trafficpolicyid))
  add(query_603838, "maxitems", newJString(maxitems))
  result = call_603837.call(nil, query_603838, nil, nil, nil)

var listTrafficPolicies* = Call_ListTrafficPolicies_603824(
    name: "listTrafficPolicies", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicies",
    validator: validate_ListTrafficPolicies_603825, base: "/",
    url: url_ListTrafficPolicies_603826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstances_603839 = ref object of OpenApiRestCall_602466
proc url_ListTrafficPolicyInstances_603841(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrafficPolicyInstances_603840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_603842 = query.getOrDefault("trafficpolicyinstancename")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "trafficpolicyinstancename", valid_603842
  var valid_603843 = query.getOrDefault("maxitems")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "maxitems", valid_603843
  var valid_603844 = query.getOrDefault("trafficpolicyinstancetype")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603844 != nil:
    section.add "trafficpolicyinstancetype", valid_603844
  var valid_603845 = query.getOrDefault("hostedzoneid")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "hostedzoneid", valid_603845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603846 = header.getOrDefault("X-Amz-Date")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-Date", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Security-Token")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Security-Token", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Content-Sha256", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Algorithm")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Algorithm", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Signature")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Signature", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-SignedHeaders", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Credential")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Credential", valid_603852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603853: Call_ListTrafficPolicyInstances_603839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603853.validator(path, query, header, formData, body)
  let scheme = call_603853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603853.url(scheme.get, call_603853.host, call_603853.base,
                         call_603853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603853, url, valid)

proc call*(call_603854: Call_ListTrafficPolicyInstances_603839;
          trafficpolicyinstancename: string = ""; maxitems: string = "";
          trafficpolicyinstancetype: string = "SOA"; hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstances
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_603855 = newJObject()
  add(query_603855, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_603855, "maxitems", newJString(maxitems))
  add(query_603855, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_603855, "hostedzoneid", newJString(hostedzoneid))
  result = call_603854.call(nil, query_603855, nil, nil, nil)

var listTrafficPolicyInstances* = Call_ListTrafficPolicyInstances_603839(
    name: "listTrafficPolicyInstances", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstances",
    validator: validate_ListTrafficPolicyInstances_603840, base: "/",
    url: url_ListTrafficPolicyInstances_603841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByHostedZone_603856 = ref object of OpenApiRestCall_602466
proc url_ListTrafficPolicyInstancesByHostedZone_603858(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrafficPolicyInstancesByHostedZone_603857(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603859 = query.getOrDefault("id")
  valid_603859 = validateParameter(valid_603859, JString, required = true,
                                 default = nil)
  if valid_603859 != nil:
    section.add "id", valid_603859
  var valid_603860 = query.getOrDefault("trafficpolicyinstancename")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "trafficpolicyinstancename", valid_603860
  var valid_603861 = query.getOrDefault("maxitems")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "maxitems", valid_603861
  var valid_603862 = query.getOrDefault("trafficpolicyinstancetype")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603862 != nil:
    section.add "trafficpolicyinstancetype", valid_603862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603863 = header.getOrDefault("X-Amz-Date")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Date", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Security-Token")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Security-Token", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Content-Sha256", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Algorithm")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Algorithm", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Signature")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Signature", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-SignedHeaders", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Credential")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Credential", valid_603869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603870: Call_ListTrafficPolicyInstancesByHostedZone_603856;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603870.validator(path, query, header, formData, body)
  let scheme = call_603870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603870.url(scheme.get, call_603870.host, call_603870.base,
                         call_603870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603870, url, valid)

proc call*(call_603871: Call_ListTrafficPolicyInstancesByHostedZone_603856;
          id: string; trafficpolicyinstancename: string = ""; maxitems: string = "";
          trafficpolicyinstancetype: string = "SOA"): Recallable =
  ## listTrafficPolicyInstancesByHostedZone
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   id: string (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_603872 = newJObject()
  add(query_603872, "id", newJString(id))
  add(query_603872, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_603872, "maxitems", newJString(maxitems))
  add(query_603872, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  result = call_603871.call(nil, query_603872, nil, nil, nil)

var listTrafficPolicyInstancesByHostedZone* = Call_ListTrafficPolicyInstancesByHostedZone_603856(
    name: "listTrafficPolicyInstancesByHostedZone", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/hostedzone#id",
    validator: validate_ListTrafficPolicyInstancesByHostedZone_603857, base: "/",
    url: url_ListTrafficPolicyInstancesByHostedZone_603858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByPolicy_603873 = ref object of OpenApiRestCall_602466
proc url_ListTrafficPolicyInstancesByPolicy_603875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrafficPolicyInstancesByPolicy_603874(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   id: JString (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: JInt (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_603876 = query.getOrDefault("id")
  valid_603876 = validateParameter(valid_603876, JString, required = true,
                                 default = nil)
  if valid_603876 != nil:
    section.add "id", valid_603876
  var valid_603877 = query.getOrDefault("trafficpolicyinstancename")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "trafficpolicyinstancename", valid_603877
  var valid_603878 = query.getOrDefault("maxitems")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "maxitems", valid_603878
  var valid_603879 = query.getOrDefault("trafficpolicyinstancetype")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = newJString("SOA"))
  if valid_603879 != nil:
    section.add "trafficpolicyinstancetype", valid_603879
  var valid_603880 = query.getOrDefault("version")
  valid_603880 = validateParameter(valid_603880, JInt, required = true, default = nil)
  if valid_603880 != nil:
    section.add "version", valid_603880
  var valid_603881 = query.getOrDefault("hostedzoneid")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "hostedzoneid", valid_603881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603882 = header.getOrDefault("X-Amz-Date")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Date", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Security-Token")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Security-Token", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Content-Sha256", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Algorithm")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Algorithm", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Signature")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Signature", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-SignedHeaders", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Credential")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Credential", valid_603888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603889: Call_ListTrafficPolicyInstancesByPolicy_603873;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_603889.validator(path, query, header, formData, body)
  let scheme = call_603889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603889.url(scheme.get, call_603889.host, call_603889.base,
                         call_603889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603889, url, valid)

proc call*(call_603890: Call_ListTrafficPolicyInstancesByPolicy_603873; id: string;
          version: int; trafficpolicyinstancename: string = ""; maxitems: string = "";
          trafficpolicyinstancetype: string = "SOA"; hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstancesByPolicy
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   id: string (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: int (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_603891 = newJObject()
  add(query_603891, "id", newJString(id))
  add(query_603891, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_603891, "maxitems", newJString(maxitems))
  add(query_603891, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_603891, "version", newJInt(version))
  add(query_603891, "hostedzoneid", newJString(hostedzoneid))
  result = call_603890.call(nil, query_603891, nil, nil, nil)

var listTrafficPolicyInstancesByPolicy* = Call_ListTrafficPolicyInstancesByPolicy_603873(
    name: "listTrafficPolicyInstancesByPolicy", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/trafficpolicy#id&version",
    validator: validate_ListTrafficPolicyInstancesByPolicy_603874, base: "/",
    url: url_ListTrafficPolicyInstancesByPolicy_603875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyVersions_603892 = ref object of OpenApiRestCall_602466
proc url_ListTrafficPolicyVersions_603894(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2013-04-01/trafficpolicies/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTrafficPolicyVersions_603893(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_603895 = path.getOrDefault("Id")
  valid_603895 = validateParameter(valid_603895, JString, required = true,
                                 default = nil)
  if valid_603895 != nil:
    section.add "Id", valid_603895
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyversion: JString
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  section = newJObject()
  var valid_603896 = query.getOrDefault("trafficpolicyversion")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "trafficpolicyversion", valid_603896
  var valid_603897 = query.getOrDefault("maxitems")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "maxitems", valid_603897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603898 = header.getOrDefault("X-Amz-Date")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Date", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Security-Token")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Security-Token", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Content-Sha256", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Algorithm")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Algorithm", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Signature")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Signature", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-SignedHeaders", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Credential")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Credential", valid_603904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603905: Call_ListTrafficPolicyVersions_603892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  let valid = call_603905.validator(path, query, header, formData, body)
  let scheme = call_603905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603905.url(scheme.get, call_603905.host, call_603905.base,
                         call_603905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603905, url, valid)

proc call*(call_603906: Call_ListTrafficPolicyVersions_603892; Id: string;
          trafficpolicyversion: string = ""; maxitems: string = ""): Recallable =
  ## listTrafficPolicyVersions
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ##   Id: string (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  ##   trafficpolicyversion: string
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  var path_603907 = newJObject()
  var query_603908 = newJObject()
  add(path_603907, "Id", newJString(Id))
  add(query_603908, "trafficpolicyversion", newJString(trafficpolicyversion))
  add(query_603908, "maxitems", newJString(maxitems))
  result = call_603906.call(path_603907, query_603908, nil, nil, nil)

var listTrafficPolicyVersions* = Call_ListTrafficPolicyVersions_603892(
    name: "listTrafficPolicyVersions", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicies/{Id}/versions",
    validator: validate_ListTrafficPolicyVersions_603893, base: "/",
    url: url_ListTrafficPolicyVersions_603894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestDNSAnswer_603909 = ref object of OpenApiRestCall_602466
proc url_TestDNSAnswer_603911(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestDNSAnswer_603910(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   resolverip: JString
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordname: JString (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   recordtype: JString (required)
  ##             : The type of the resource record set.
  ##   edns0clientsubnetmask: JString
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   edns0clientsubnetip: JString
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   hostedzoneid: JString (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  section = newJObject()
  var valid_603912 = query.getOrDefault("resolverip")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "resolverip", valid_603912
  assert query != nil,
        "query argument is necessary due to required `recordname` field"
  var valid_603913 = query.getOrDefault("recordname")
  valid_603913 = validateParameter(valid_603913, JString, required = true,
                                 default = nil)
  if valid_603913 != nil:
    section.add "recordname", valid_603913
  var valid_603914 = query.getOrDefault("recordtype")
  valid_603914 = validateParameter(valid_603914, JString, required = true,
                                 default = newJString("SOA"))
  if valid_603914 != nil:
    section.add "recordtype", valid_603914
  var valid_603915 = query.getOrDefault("edns0clientsubnetmask")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "edns0clientsubnetmask", valid_603915
  var valid_603916 = query.getOrDefault("edns0clientsubnetip")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "edns0clientsubnetip", valid_603916
  var valid_603917 = query.getOrDefault("hostedzoneid")
  valid_603917 = validateParameter(valid_603917, JString, required = true,
                                 default = nil)
  if valid_603917 != nil:
    section.add "hostedzoneid", valid_603917
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603918 = header.getOrDefault("X-Amz-Date")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Date", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Security-Token")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Security-Token", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Content-Sha256", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Algorithm")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Algorithm", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Signature")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Signature", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-SignedHeaders", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Credential")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Credential", valid_603924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603925: Call_TestDNSAnswer_603909; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  let valid = call_603925.validator(path, query, header, formData, body)
  let scheme = call_603925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603925.url(scheme.get, call_603925.host, call_603925.base,
                         call_603925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603925, url, valid)

proc call*(call_603926: Call_TestDNSAnswer_603909; recordname: string;
          hostedzoneid: string; resolverip: string = ""; recordtype: string = "SOA";
          edns0clientsubnetmask: string = ""; edns0clientsubnetip: string = ""): Recallable =
  ## testDNSAnswer
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ##   resolverip: string
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordname: string (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   recordtype: string (required)
  ##             : The type of the resource record set.
  ##   edns0clientsubnetmask: string
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   edns0clientsubnetip: string
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   hostedzoneid: string (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  var query_603927 = newJObject()
  add(query_603927, "resolverip", newJString(resolverip))
  add(query_603927, "recordname", newJString(recordname))
  add(query_603927, "recordtype", newJString(recordtype))
  add(query_603927, "edns0clientsubnetmask", newJString(edns0clientsubnetmask))
  add(query_603927, "edns0clientsubnetip", newJString(edns0clientsubnetip))
  add(query_603927, "hostedzoneid", newJString(hostedzoneid))
  result = call_603926.call(nil, query_603927, nil, nil, nil)

var testDNSAnswer* = Call_TestDNSAnswer_603909(name: "testDNSAnswer",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/testdnsanswer#hostedzoneid&recordname&recordtype",
    validator: validate_TestDNSAnswer_603910, base: "/", url: url_TestDNSAnswer_603911,
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
