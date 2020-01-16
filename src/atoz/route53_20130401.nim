
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  awsServers = {Scheme.Http: {"cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
                           "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "route53.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "route53.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "route53"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateVPCWithHostedZone_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateVPCWithHostedZone_605929(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AssociateVPCWithHostedZone_605928(path: JsonNode; query: JsonNode;
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
  var valid_606055 = path.getOrDefault("Id")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "Id", valid_606055
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
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_AssociateVPCWithHostedZone_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_AssociateVPCWithHostedZone_605927; body: JsonNode;
          Id: string): Recallable =
  ## associateVPCWithHostedZone
  ## <p>Associates an Amazon VPC with a private hosted zone. </p> <important> <p>To perform the association, the VPC and the private hosted zone must already exist. You can't convert a public hosted zone into a private hosted zone.</p> </important> <note> <p>If you want to associate a VPC that was created by using one AWS account with a private hosted zone that was created by using a different account, the AWS account that created the private hosted zone must first submit a <code>CreateVPCAssociationAuthorization</code> request. Then the account that created the VPC must submit an <code>AssociateVPCWithHostedZone</code> request.</p> </note>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : <p>The ID of the private hosted zone that you want to associate an Amazon VPC with.</p> <p>Note that you can't associate a VPC with a hosted zone that doesn't have an existing VPC association.</p>
  var path_606158 = newJObject()
  var body_606160 = newJObject()
  if body != nil:
    body_606160 = body
  add(path_606158, "Id", newJString(Id))
  result = call_606157.call(path_606158, nil, nil, nil, body_606160)

var associateVPCWithHostedZone* = Call_AssociateVPCWithHostedZone_605927(
    name: "associateVPCWithHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/associatevpc",
    validator: validate_AssociateVPCWithHostedZone_605928, base: "/",
    url: url_AssociateVPCWithHostedZone_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeResourceRecordSets_606199 = ref object of OpenApiRestCall_605589
proc url_ChangeResourceRecordSets_606201(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ChangeResourceRecordSets_606200(path: JsonNode; query: JsonNode;
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
  var valid_606202 = path.getOrDefault("Id")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "Id", valid_606202
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
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_ChangeResourceRecordSets_606199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_ChangeResourceRecordSets_606199; body: JsonNode;
          Id: string): Recallable =
  ## changeResourceRecordSets
  ## <p>Creates, changes, or deletes a resource record set, which contains authoritative DNS information for a specified domain name or subdomain name. For example, you can use <code>ChangeResourceRecordSets</code> to create a resource record set that routes traffic for test.example.com to a web server that has an IP address of 192.0.2.44.</p> <p> <b>Change Batches and Transactional Changes</b> </p> <p>The request body must include a document with a <code>ChangeResourceRecordSetsRequest</code> element. The request body contains a list of change items, known as a change batch. Change batches are considered transactional changes. When using the Amazon Route 53 API to change resource record sets, Route 53 either makes all or none of the changes in a change batch request. This ensures that Route 53 never partially implements the intended changes to the resource record sets in a hosted zone. </p> <p>For example, a change batch request that deletes the <code>CNAME</code> record for www.example.com and creates an alias resource record set for www.example.com. Route 53 deletes the first resource record set and creates the second resource record set in a single operation. If either the <code>DELETE</code> or the <code>CREATE</code> action fails, then both changes (plus any other changes in the batch) fail, and the original <code>CNAME</code> record continues to exist.</p> <important> <p>Due to the nature of transactional changes, you can't delete the same resource record set more than once in a single change batch. If you attempt to delete the same change batch more than once, Route 53 returns an <code>InvalidChangeBatch</code> error.</p> </important> <p> <b>Traffic Flow</b> </p> <p>To create resource record sets for complex routing configurations, use either the traffic flow visual editor in the Route 53 console or the API actions for traffic policies and traffic policy instances. Save the configuration as a traffic policy, then associate the traffic policy with one or more domain names (such as example.com) or subdomain names (such as www.example.com), in the same hosted zone or in multiple hosted zones. You can roll back the updates if the new configuration isn't performing as expected. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/traffic-flow.html">Using Traffic Flow to Route DNS Traffic</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p> <b>Create, Delete, and Upsert</b> </p> <p>Use <code>ChangeResourceRecordsSetsRequest</code> to perform the following actions:</p> <ul> <li> <p> <code>CREATE</code>: Creates a resource record set that has the specified values.</p> </li> <li> <p> <code>DELETE</code>: Deletes an existing resource record set that has the specified values.</p> </li> <li> <p> <code>UPSERT</code>: If a resource record set does not already exist, AWS creates it. If a resource set does exist, Route 53 updates it with the values in the request. </p> </li> </ul> <p> <b>Syntaxes for Creating, Updating, and Deleting Resource Record Sets</b> </p> <p>The syntax for a request depends on the type of resource record set that you want to create, delete, or update, such as weighted, alias, or failover. The XML elements in your request must appear in the order listed in the syntax. </p> <p>For an example for each type of resource record set, see "Examples."</p> <p>Don't refer to the syntax in the "Parameter Syntax" section, which includes all of the elements for every kind of resource record set that you can create, delete, or update by using <code>ChangeResourceRecordSets</code>. </p> <p> <b>Change Propagation to Route 53 DNS Servers</b> </p> <p>When you submit a <code>ChangeResourceRecordSets</code> request, Route 53 propagates your changes to all of the Route 53 authoritative DNS servers. While your changes are propagating, <code>GetChange</code> returns a status of <code>PENDING</code>. When propagation is complete, <code>GetChange</code> returns a status of <code>INSYNC</code>. Changes generally propagate to all Route 53 name servers within 60 seconds. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html">GetChange</a>.</p> <p> <b>Limits on ChangeResourceRecordSets Requests</b> </p> <p>For information about the limits on a <code>ChangeResourceRecordSets</code> request, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to change.
  var path_606213 = newJObject()
  var body_606214 = newJObject()
  if body != nil:
    body_606214 = body
  add(path_606213, "Id", newJString(Id))
  result = call_606212.call(path_606213, nil, nil, nil, body_606214)

var changeResourceRecordSets* = Call_ChangeResourceRecordSets_606199(
    name: "changeResourceRecordSets", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset/",
    validator: validate_ChangeResourceRecordSets_606200, base: "/",
    url: url_ChangeResourceRecordSets_606201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ChangeTagsForResource_606243 = ref object of OpenApiRestCall_605589
proc url_ChangeTagsForResource_606245(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ChangeTagsForResource_606244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_606246 = path.getOrDefault("ResourceId")
  valid_606246 = validateParameter(valid_606246, JString, required = true,
                                 default = nil)
  if valid_606246 != nil:
    section.add "ResourceId", valid_606246
  var valid_606247 = path.getOrDefault("ResourceType")
  valid_606247 = validateParameter(valid_606247, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_606247 != nil:
    section.add "ResourceType", valid_606247
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
  var valid_606248 = header.getOrDefault("X-Amz-Signature")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Signature", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Content-Sha256", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Date")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Date", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Credential")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Credential", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Security-Token")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Security-Token", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Algorithm")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Algorithm", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-SignedHeaders", valid_606254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606256: Call_ChangeTagsForResource_606243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_606256.validator(path, query, header, formData, body)
  let scheme = call_606256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606256.url(scheme.get, call_606256.host, call_606256.base,
                         call_606256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606256, url, valid)

proc call*(call_606257: Call_ChangeTagsForResource_606243; ResourceId: string;
          body: JsonNode; ResourceType: string = "healthcheck"): Recallable =
  ## changeTagsForResource
  ## <p>Adds, edits, or deletes tags for a health check or a hosted zone.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to add, change, or delete tags.
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_606258 = newJObject()
  var body_606259 = newJObject()
  add(path_606258, "ResourceId", newJString(ResourceId))
  add(path_606258, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_606259 = body
  result = call_606257.call(path_606258, nil, nil, nil, body_606259)

var changeTagsForResource* = Call_ChangeTagsForResource_606243(
    name: "changeTagsForResource", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ChangeTagsForResource_606244, base: "/",
    url: url_ChangeTagsForResource_606245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606215 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606217(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606216(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceId: JString (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  ##   ResourceType: JString (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceId` field"
  var valid_606218 = path.getOrDefault("ResourceId")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "ResourceId", valid_606218
  var valid_606232 = path.getOrDefault("ResourceType")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_606232 != nil:
    section.add "ResourceType", valid_606232
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
  var valid_606233 = header.getOrDefault("X-Amz-Signature")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Signature", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Content-Sha256", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Date")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Date", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Credential")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Credential", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Security-Token")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Security-Token", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Algorithm")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Algorithm", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-SignedHeaders", valid_606239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606240: Call_ListTagsForResource_606215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_606240.validator(path, query, header, formData, body)
  let scheme = call_606240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606240.url(scheme.get, call_606240.host, call_606240.base,
                         call_606240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606240, url, valid)

proc call*(call_606241: Call_ListTagsForResource_606215; ResourceId: string;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResource
  ## <p>Lists tags for one health check or hosted zone. </p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceId: string (required)
  ##             : The ID of the resource for which you want to retrieve tags.
  ##   ResourceType: string (required)
  ##               : <p>The type of the resource.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  var path_606242 = newJObject()
  add(path_606242, "ResourceId", newJString(ResourceId))
  add(path_606242, "ResourceType", newJString(ResourceType))
  result = call_606241.call(path_606242, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606215(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/tags/{ResourceType}/{ResourceId}",
    validator: validate_ListTagsForResource_606216, base: "/",
    url: url_ListTagsForResource_606217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHealthCheck_606277 = ref object of OpenApiRestCall_605589
proc url_CreateHealthCheck_606279(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHealthCheck_606278(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606280 = header.getOrDefault("X-Amz-Signature")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Signature", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Content-Sha256", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Date")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Date", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Credential")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Credential", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Security-Token")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Security-Token", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Algorithm")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Algorithm", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-SignedHeaders", valid_606286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606288: Call_CreateHealthCheck_606277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ## 
  let valid = call_606288.validator(path, query, header, formData, body)
  let scheme = call_606288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606288.url(scheme.get, call_606288.host, call_606288.base,
                         call_606288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606288, url, valid)

proc call*(call_606289: Call_CreateHealthCheck_606277; body: JsonNode): Recallable =
  ## createHealthCheck
  ## <p>Creates a new health check.</p> <p>For information about adding health checks to resource record sets, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ResourceRecordSet.html#Route53-Type-ResourceRecordSet-HealthCheckId">HealthCheckId</a> in <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>. </p> <p> <b>ELB Load Balancers</b> </p> <p>If you're registering EC2 instances with an Elastic Load Balancing (ELB) load balancer, do not create Amazon Route 53 health checks for the EC2 instances. When you register an EC2 instance with a load balancer, you configure settings for an ELB health check, which performs a similar function to a Route 53 health check.</p> <p> <b>Private Hosted Zones</b> </p> <p>You can associate health checks with failover resource record sets in a private hosted zone. Note the following:</p> <ul> <li> <p>Route 53 health checkers are outside the VPC. To check the health of an endpoint within a VPC by IP address, you must assign a public IP address to the instance in the VPC.</p> </li> <li> <p>You can configure a health checker to check the health of an external resource that the instance relies on, such as a database server.</p> </li> <li> <p>You can create a CloudWatch metric, associate an alarm with the metric, and then create a health check that is based on the state of the alarm. For example, you might create a CloudWatch metric that checks the status of the Amazon EC2 <code>StatusCheckFailed</code> metric, add an alarm to the metric, and then create a health check that is based on the state of the alarm. For information about creating CloudWatch metrics and alarms by using the CloudWatch console, see the <a href="http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/WhatIsCloudWatch.html">Amazon CloudWatch User Guide</a>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606290 = newJObject()
  if body != nil:
    body_606290 = body
  result = call_606289.call(nil, nil, nil, nil, body_606290)

var createHealthCheck* = Call_CreateHealthCheck_606277(name: "createHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_CreateHealthCheck_606278,
    base: "/", url: url_CreateHealthCheck_606279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHealthChecks_606260 = ref object of OpenApiRestCall_605589
proc url_ListHealthChecks_606262(protocol: Scheme; host: string; base: string;
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

proc validate_ListHealthChecks_606261(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   maxitems: JString
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  section = newJObject()
  var valid_606263 = query.getOrDefault("Marker")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "Marker", valid_606263
  var valid_606264 = query.getOrDefault("MaxItems")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "MaxItems", valid_606264
  var valid_606265 = query.getOrDefault("maxitems")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "maxitems", valid_606265
  var valid_606266 = query.getOrDefault("marker")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "marker", valid_606266
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
  var valid_606267 = header.getOrDefault("X-Amz-Signature")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Signature", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Content-Sha256", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Date")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Date", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Credential")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Credential", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Security-Token")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Security-Token", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Algorithm")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Algorithm", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-SignedHeaders", valid_606273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606274: Call_ListHealthChecks_606260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ## 
  let valid = call_606274.validator(path, query, header, formData, body)
  let scheme = call_606274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606274.url(scheme.get, call_606274.host, call_606274.base,
                         call_606274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606274, url, valid)

proc call*(call_606275: Call_ListHealthChecks_606260; Marker: string = "";
          MaxItems: string = ""; maxitems: string = ""; marker: string = ""): Recallable =
  ## listHealthChecks
  ## Retrieve a list of the health checks that are associated with the current AWS account. 
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  ##   maxitems: string
  ##           : The maximum number of health checks that you want <code>ListHealthChecks</code> to return in response to the current request. Amazon Route 53 returns a maximum of 100 items. If you set <code>MaxItems</code> to a value greater than 100, Route 53 returns only the first 100 health checks. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more health checks. To get another group, submit another <code>ListHealthChecks</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first health check that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more health checks to get.</p>
  var query_606276 = newJObject()
  add(query_606276, "Marker", newJString(Marker))
  add(query_606276, "MaxItems", newJString(MaxItems))
  add(query_606276, "maxitems", newJString(maxitems))
  add(query_606276, "marker", newJString(marker))
  result = call_606275.call(nil, query_606276, nil, nil, nil)

var listHealthChecks* = Call_ListHealthChecks_606260(name: "listHealthChecks",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck", validator: validate_ListHealthChecks_606261,
    base: "/", url: url_ListHealthChecks_606262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHostedZone_606309 = ref object of OpenApiRestCall_605589
proc url_CreateHostedZone_606311(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHostedZone_606310(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606312 = header.getOrDefault("X-Amz-Signature")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Signature", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Content-Sha256", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Date")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Date", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Credential")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Credential", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Security-Token")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Security-Token", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Algorithm")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Algorithm", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-SignedHeaders", valid_606318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_CreateHostedZone_606309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_CreateHostedZone_606309; body: JsonNode): Recallable =
  ## createHostedZone
  ## <p>Creates a new public or private hosted zone. You create records in a public hosted zone to define how you want to route traffic on the internet for a domain, such as example.com, and its subdomains (apex.example.com, acme.example.com). You create records in a private hosted zone to define how you want to route traffic for a domain and its subdomains within one or more Amazon Virtual Private Clouds (Amazon VPCs). </p> <important> <p>You can't convert a public hosted zone to a private hosted zone or vice versa. Instead, you must create a new hosted zone with the same name and create new resource record sets.</p> </important> <p>For more information about charges for hosted zones, see <a href="http://aws.amazon.com/route53/pricing/">Amazon Route 53 Pricing</a>.</p> <p>Note the following:</p> <ul> <li> <p>You can't create a hosted zone for a top-level domain (TLD) such as .com.</p> </li> <li> <p>For public hosted zones, Amazon Route 53 automatically creates a default SOA record and four NS records for the zone. For more information about SOA and NS records, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html">NS and SOA Records that Route 53 Creates for a Hosted Zone</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>If you want to use the same name servers for multiple public hosted zones, you can optionally associate a reusable delegation set with the hosted zone. See the <code>DelegationSetId</code> element.</p> </li> <li> <p>If your domain is registered with a registrar other than Route 53, you must update the name servers with your registrar to make Route 53 the DNS service for the domain. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html">Migrating DNS Service for an Existing Domain to Amazon Route 53</a> in the <i>Amazon Route 53 Developer Guide</i>. </p> </li> </ul> <p>When you submit a <code>CreateHostedZone</code> request, the initial status of the hosted zone is <code>PENDING</code>. For public hosted zones, this means that the NS and SOA records are not yet available on all Route 53 DNS servers. When the NS and SOA records are available, the status of the zone changes to <code>INSYNC</code>.</p>
  ##   body: JObject (required)
  var body_606322 = newJObject()
  if body != nil:
    body_606322 = body
  result = call_606321.call(nil, nil, nil, nil, body_606322)

var createHostedZone* = Call_CreateHostedZone_606309(name: "createHostedZone",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_CreateHostedZone_606310,
    base: "/", url: url_CreateHostedZone_606311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZones_606291 = ref object of OpenApiRestCall_605589
proc url_ListHostedZones_606293(protocol: Scheme; host: string; base: string;
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

proc validate_ListHostedZones_606292(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   maxitems: JString
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   delegationsetid: JString
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  section = newJObject()
  var valid_606294 = query.getOrDefault("Marker")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "Marker", valid_606294
  var valid_606295 = query.getOrDefault("MaxItems")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "MaxItems", valid_606295
  var valid_606296 = query.getOrDefault("maxitems")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "maxitems", valid_606296
  var valid_606297 = query.getOrDefault("delegationsetid")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "delegationsetid", valid_606297
  var valid_606298 = query.getOrDefault("marker")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "marker", valid_606298
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
  var valid_606299 = header.getOrDefault("X-Amz-Signature")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Signature", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Content-Sha256", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Date")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Date", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Credential")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Credential", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Security-Token")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Security-Token", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Algorithm")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Algorithm", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-SignedHeaders", valid_606305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606306: Call_ListHostedZones_606291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_606306.validator(path, query, header, formData, body)
  let scheme = call_606306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606306.url(scheme.get, call_606306.host, call_606306.base,
                         call_606306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606306, url, valid)

proc call*(call_606307: Call_ListHostedZones_606291; Marker: string = "";
          MaxItems: string = ""; maxitems: string = ""; delegationsetid: string = "";
          marker: string = ""): Recallable =
  ## listHostedZones
  ## <p>Retrieves a list of the public and private hosted zones that are associated with the current AWS account. The response includes a <code>HostedZones</code> child element for each hosted zone.</p> <p>Amazon Route 53 returns a maximum of 100 items in each response. If you have a lot of hosted zones, you can use the <code>maxitems</code> parameter to list them in groups of up to 100.</p>
  ##   Marker: string
  ##         : Pagination token
  ##   MaxItems: string
  ##           : Pagination limit
  ##   maxitems: string
  ##           : (Optional) The maximum number of hosted zones that you want Amazon Route 53 to return. If you have more than <code>maxitems</code> hosted zones, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>NextMarker</code> is the hosted zone ID of the first hosted zone that Route 53 will return if you submit another request.
  ##   delegationsetid: string
  ##                  : If you're using reusable delegation sets and you want to list all of the hosted zones that are associated with a reusable delegation set, specify the ID of that reusable delegation set. 
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more hosted zones. To get more hosted zones, submit another <code>ListHostedZones</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first hosted zone that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more hosted zones to get.</p>
  var query_606308 = newJObject()
  add(query_606308, "Marker", newJString(Marker))
  add(query_606308, "MaxItems", newJString(MaxItems))
  add(query_606308, "maxitems", newJString(maxitems))
  add(query_606308, "delegationsetid", newJString(delegationsetid))
  add(query_606308, "marker", newJString(marker))
  result = call_606307.call(nil, query_606308, nil, nil, nil)

var listHostedZones* = Call_ListHostedZones_606291(name: "listHostedZones",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone", validator: validate_ListHostedZones_606292,
    base: "/", url: url_ListHostedZones_606293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateQueryLoggingConfig_606339 = ref object of OpenApiRestCall_605589
proc url_CreateQueryLoggingConfig_606341(protocol: Scheme; host: string;
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

proc validate_CreateQueryLoggingConfig_606340(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606342 = header.getOrDefault("X-Amz-Signature")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Signature", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Content-Sha256", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Date")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Date", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Credential")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Credential", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Security-Token")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Security-Token", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Algorithm")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Algorithm", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-SignedHeaders", valid_606348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_CreateQueryLoggingConfig_606339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_CreateQueryLoggingConfig_606339; body: JsonNode): Recallable =
  ## createQueryLoggingConfig
  ## <p>Creates a configuration for DNS query logging. After you create a query logging configuration, Amazon Route 53 begins to publish log data to an Amazon CloudWatch Logs log group.</p> <p>DNS query logs contain information about the queries that Route 53 receives for a specified public hosted zone, such as the following:</p> <ul> <li> <p>Route 53 edge location that responded to the DNS query</p> </li> <li> <p>Domain or subdomain that was requested</p> </li> <li> <p>DNS record type, such as A or AAAA</p> </li> <li> <p>DNS response code, such as <code>NoError</code> or <code>ServFail</code> </p> </li> </ul> <dl> <dt>Log Group and Resource Policy</dt> <dd> <p>Before you create a query logging configuration, perform the following operations.</p> <note> <p>If you create a query logging configuration using the Route 53 console, Route 53 performs these operations automatically.</p> </note> <ol> <li> <p>Create a CloudWatch Logs log group, and make note of the ARN, which you specify when you create a query logging configuration. Note the following:</p> <ul> <li> <p>You must create the log group in the us-east-1 region.</p> </li> <li> <p>You must use the same AWS account to create the log group and the hosted zone that you want to configure query logging for.</p> </li> <li> <p>When you create log groups for query logging, we recommend that you use a consistent prefix, for example:</p> <p> <code>/aws/route53/<i>hosted zone name</i> </code> </p> <p>In the next step, you'll create a resource policy, which controls access to one or more log groups and the associated AWS resources, such as Route 53 hosted zones. There's a limit on the number of resource policies that you can create, so we recommend that you use a consistent prefix so you can use the same resource policy for all the log groups that you create for query logging.</p> </li> </ul> </li> <li> <p>Create a CloudWatch Logs resource policy, and give it the permissions that Route 53 needs to create log streams and to send query logs to log streams. For the value of <code>Resource</code>, specify the ARN for the log group that you created in the previous step. To use the same resource policy for all the CloudWatch Logs log groups that you created for query logging configurations, replace the hosted zone name with <code>*</code>, for example:</p> <p> <code>arn:aws:logs:us-east-1:123412341234:log-group:/aws/route53/*</code> </p> <note> <p>You can't use the CloudWatch console to create or edit a resource policy. You must use the CloudWatch API, one of the AWS SDKs, or the AWS CLI.</p> </note> </li> </ol> </dd> <dt>Log Streams and Edge Locations</dt> <dd> <p>When Route 53 finishes creating the configuration for DNS query logging, it does the following:</p> <ul> <li> <p>Creates a log stream for an edge location the first time that the edge location responds to DNS queries for the specified hosted zone. That log stream is used to log all queries that Route 53 responds to for that edge location.</p> </li> <li> <p>Begins to send query logs to the applicable log stream.</p> </li> </ul> <p>The name of each log stream is in the following format:</p> <p> <code> <i>hosted zone ID</i>/<i>edge location code</i> </code> </p> <p>The edge location code is a three-letter code and an arbitrarily assigned number, for example, DFW3. The three-letter code typically corresponds with the International Air Transport Association airport code for an airport near the edge location. (These abbreviations might change in the future.) For a list of edge locations, see "The Route 53 Global Network" on the <a href="http://aws.amazon.com/route53/details/">Route 53 Product Details</a> page.</p> </dd> <dt>Queries That Are Logged</dt> <dd> <p>Query logs contain only the queries that DNS resolvers forward to Route 53. If a DNS resolver has already cached the response to a query (such as the IP address for a load balancer for example.com), the resolver will continue to return the cached response. It doesn't forward another query to Route 53 until the TTL for the corresponding resource record set expires. Depending on how many DNS queries are submitted for a resource record set, and depending on the TTL for that resource record set, query logs might contain information about only one query out of every several thousand queries that are submitted to DNS. For more information about how DNS works, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html">Routing Internet Traffic to Your Website or Web Application</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Log File Format</dt> <dd> <p>For a list of the values in each query log and the format of each value, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </dd> <dt>Pricing</dt> <dd> <p>For information about charges for query logs, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </dd> <dt>How to Stop Logging</dt> <dd> <p>If you want Route 53 to stop sending query logs to CloudWatch Logs, delete the query logging configuration. For more information, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_DeleteQueryLoggingConfig.html">DeleteQueryLoggingConfig</a>.</p> </dd> </dl>
  ##   body: JObject (required)
  var body_606352 = newJObject()
  if body != nil:
    body_606352 = body
  result = call_606351.call(nil, nil, nil, nil, body_606352)

var createQueryLoggingConfig* = Call_CreateQueryLoggingConfig_606339(
    name: "createQueryLoggingConfig", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_CreateQueryLoggingConfig_606340, base: "/",
    url: url_CreateQueryLoggingConfig_606341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListQueryLoggingConfigs_606323 = ref object of OpenApiRestCall_605589
proc url_ListQueryLoggingConfigs_606325(protocol: Scheme; host: string; base: string;
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

proc validate_ListQueryLoggingConfigs_606324(path: JsonNode; query: JsonNode;
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
  var valid_606326 = query.getOrDefault("nexttoken")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "nexttoken", valid_606326
  var valid_606327 = query.getOrDefault("maxresults")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "maxresults", valid_606327
  var valid_606328 = query.getOrDefault("hostedzoneid")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "hostedzoneid", valid_606328
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

proc call*(call_606336: Call_ListQueryLoggingConfigs_606323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the configurations for DNS query logging that are associated with the current AWS account or the configuration that is associated with a specified hosted zone.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>. Additional information, including the format of DNS query logs, appears in <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_606336.validator(path, query, header, formData, body)
  let scheme = call_606336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606336.url(scheme.get, call_606336.host, call_606336.base,
                         call_606336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606336, url, valid)

proc call*(call_606337: Call_ListQueryLoggingConfigs_606323;
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
  var query_606338 = newJObject()
  add(query_606338, "nexttoken", newJString(nexttoken))
  add(query_606338, "maxresults", newJString(maxresults))
  add(query_606338, "hostedzoneid", newJString(hostedzoneid))
  result = call_606337.call(nil, query_606338, nil, nil, nil)

var listQueryLoggingConfigs* = Call_ListQueryLoggingConfigs_606323(
    name: "listQueryLoggingConfigs", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig",
    validator: validate_ListQueryLoggingConfigs_606324, base: "/",
    url: url_ListQueryLoggingConfigs_606325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateReusableDelegationSet_606368 = ref object of OpenApiRestCall_605589
proc url_CreateReusableDelegationSet_606370(protocol: Scheme; host: string;
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

proc validate_CreateReusableDelegationSet_606369(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606371 = header.getOrDefault("X-Amz-Signature")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Signature", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Content-Sha256", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Date")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Date", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Credential")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Credential", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Security-Token")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Security-Token", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Algorithm")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Algorithm", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-SignedHeaders", valid_606377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606379: Call_CreateReusableDelegationSet_606368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ## 
  let valid = call_606379.validator(path, query, header, formData, body)
  let scheme = call_606379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606379.url(scheme.get, call_606379.host, call_606379.base,
                         call_606379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606379, url, valid)

proc call*(call_606380: Call_CreateReusableDelegationSet_606368; body: JsonNode): Recallable =
  ## createReusableDelegationSet
  ## <p>Creates a delegation set (a group of four name servers) that can be reused by multiple hosted zones. If a hosted zoned ID is specified, <code>CreateReusableDelegationSet</code> marks the delegation set associated with that zone as reusable.</p> <note> <p>You can't associate a reusable delegation set with a private hosted zone.</p> </note> <p>For information about using a reusable delegation set to configure white label name servers, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/white-label-name-servers.html">Configuring White Label Name Servers</a>.</p> <p>The process for migrating existing hosted zones to use a reusable delegation set is comparable to the process for configuring white label name servers. You need to perform the following steps:</p> <ol> <li> <p>Create a reusable delegation set.</p> </li> <li> <p>Recreate hosted zones, and reduce the TTL to 60 seconds or less.</p> </li> <li> <p>Recreate resource record sets in the new hosted zones.</p> </li> <li> <p>Change the registrar's name servers to use the name servers for the new hosted zones.</p> </li> <li> <p>Monitor traffic for the website or application.</p> </li> <li> <p>Change TTLs back to their original values.</p> </li> </ol> <p>If you want to migrate existing hosted zones to use a reusable delegation set, the existing hosted zones can't use any of the name servers that are assigned to the reusable delegation set. If one or more hosted zones do use one or more name servers that are assigned to the reusable delegation set, you can do one of the following:</p> <ul> <li> <p>For small numbers of hosted zones—up to a few hundred—it's relatively easy to create reusable delegation sets until you get one that has four name servers that don't overlap with any of the name servers in your hosted zones.</p> </li> <li> <p>For larger numbers of hosted zones, the easiest solution is to use more than one reusable delegation set.</p> </li> <li> <p>For larger numbers of hosted zones, you can also migrate hosted zones that have overlapping name servers to hosted zones that don't have overlapping name servers, then migrate the hosted zones again to use the reusable delegation set.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606381 = newJObject()
  if body != nil:
    body_606381 = body
  result = call_606380.call(nil, nil, nil, nil, body_606381)

var createReusableDelegationSet* = Call_CreateReusableDelegationSet_606368(
    name: "createReusableDelegationSet", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_CreateReusableDelegationSet_606369, base: "/",
    url: url_CreateReusableDelegationSet_606370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReusableDelegationSets_606353 = ref object of OpenApiRestCall_605589
proc url_ListReusableDelegationSets_606355(protocol: Scheme; host: string;
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

proc validate_ListReusableDelegationSets_606354(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  ##   marker: JString
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  section = newJObject()
  var valid_606356 = query.getOrDefault("maxitems")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "maxitems", valid_606356
  var valid_606357 = query.getOrDefault("marker")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "marker", valid_606357
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

proc call*(call_606365: Call_ListReusableDelegationSets_606353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ## 
  let valid = call_606365.validator(path, query, header, formData, body)
  let scheme = call_606365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606365.url(scheme.get, call_606365.host, call_606365.base,
                         call_606365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606365, url, valid)

proc call*(call_606366: Call_ListReusableDelegationSets_606353;
          maxitems: string = ""; marker: string = ""): Recallable =
  ## listReusableDelegationSets
  ## Retrieves a list of the reusable delegation sets that are associated with the current AWS account.
  ##   maxitems: string
  ##           : The number of reusable delegation sets that you want Amazon Route 53 to return in the response to this request. If you specify a value greater than 100, Route 53 returns only the first 100 reusable delegation sets.
  ##   marker: string
  ##         : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more reusable delegation sets. To get another group, submit another <code>ListReusableDelegationSets</code> request. </p> <p>For the value of <code>marker</code>, specify the value of <code>NextMarker</code> from the previous response, which is the ID of the first reusable delegation set that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more reusable delegation sets to get.</p>
  var query_606367 = newJObject()
  add(query_606367, "maxitems", newJString(maxitems))
  add(query_606367, "marker", newJString(marker))
  result = call_606366.call(nil, query_606367, nil, nil, nil)

var listReusableDelegationSets* = Call_ListReusableDelegationSets_606353(
    name: "listReusableDelegationSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset",
    validator: validate_ListReusableDelegationSets_606354, base: "/",
    url: url_ListReusableDelegationSets_606355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicy_606382 = ref object of OpenApiRestCall_605589
proc url_CreateTrafficPolicy_606384(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrafficPolicy_606383(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606385 = header.getOrDefault("X-Amz-Signature")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Signature", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Content-Sha256", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Date")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Date", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Credential")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Credential", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Security-Token")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Security-Token", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Algorithm")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Algorithm", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-SignedHeaders", valid_606391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606393: Call_CreateTrafficPolicy_606382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ## 
  let valid = call_606393.validator(path, query, header, formData, body)
  let scheme = call_606393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606393.url(scheme.get, call_606393.host, call_606393.base,
                         call_606393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606393, url, valid)

proc call*(call_606394: Call_CreateTrafficPolicy_606382; body: JsonNode): Recallable =
  ## createTrafficPolicy
  ## Creates a traffic policy, which you use to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com).
  ##   body: JObject (required)
  var body_606395 = newJObject()
  if body != nil:
    body_606395 = body
  result = call_606394.call(nil, nil, nil, nil, body_606395)

var createTrafficPolicy* = Call_CreateTrafficPolicy_606382(
    name: "createTrafficPolicy", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy",
    validator: validate_CreateTrafficPolicy_606383, base: "/",
    url: url_CreateTrafficPolicy_606384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyInstance_606396 = ref object of OpenApiRestCall_605589
proc url_CreateTrafficPolicyInstance_606398(protocol: Scheme; host: string;
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

proc validate_CreateTrafficPolicyInstance_606397(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606399 = header.getOrDefault("X-Amz-Signature")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Signature", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Content-Sha256", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Date")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Date", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Credential")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Credential", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Security-Token")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Security-Token", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Algorithm")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Algorithm", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-SignedHeaders", valid_606405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_CreateTrafficPolicyInstance_606396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ## 
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_CreateTrafficPolicyInstance_606396; body: JsonNode): Recallable =
  ## createTrafficPolicyInstance
  ## Creates resource record sets in a specified hosted zone based on the settings in a specified traffic policy version. In addition, <code>CreateTrafficPolicyInstance</code> associates the resource record sets with a specified domain name (such as example.com) or subdomain name (such as www.example.com). Amazon Route 53 responds to DNS queries for the domain or subdomain name by using the resource record sets that <code>CreateTrafficPolicyInstance</code> created.
  ##   body: JObject (required)
  var body_606409 = newJObject()
  if body != nil:
    body_606409 = body
  result = call_606408.call(nil, nil, nil, nil, body_606409)

var createTrafficPolicyInstance* = Call_CreateTrafficPolicyInstance_606396(
    name: "createTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstance",
    validator: validate_CreateTrafficPolicyInstance_606397, base: "/",
    url: url_CreateTrafficPolicyInstance_606398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrafficPolicyVersion_606410 = ref object of OpenApiRestCall_605589
proc url_CreateTrafficPolicyVersion_606412(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTrafficPolicyVersion_606411(path: JsonNode; query: JsonNode;
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
  var valid_606413 = path.getOrDefault("Id")
  valid_606413 = validateParameter(valid_606413, JString, required = true,
                                 default = nil)
  if valid_606413 != nil:
    section.add "Id", valid_606413
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
  var valid_606414 = header.getOrDefault("X-Amz-Signature")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Signature", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Content-Sha256", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Date")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Date", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Credential")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Credential", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Security-Token")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Security-Token", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Algorithm")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Algorithm", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-SignedHeaders", valid_606420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606422: Call_CreateTrafficPolicyVersion_606410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ## 
  let valid = call_606422.validator(path, query, header, formData, body)
  let scheme = call_606422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606422.url(scheme.get, call_606422.host, call_606422.base,
                         call_606422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606422, url, valid)

proc call*(call_606423: Call_CreateTrafficPolicyVersion_606410; body: JsonNode;
          Id: string): Recallable =
  ## createTrafficPolicyVersion
  ## Creates a new version of an existing traffic policy. When you create a new version of a traffic policy, you specify the ID of the traffic policy that you want to update and a JSON-formatted document that describes the new version. You use traffic policies to create multiple DNS resource record sets for one domain name (such as example.com) or one subdomain name (such as www.example.com). You can create a maximum of 1000 versions of a traffic policy. If you reach the limit and need to create another version, you'll need to start a new traffic policy.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the traffic policy for which you want to create a new version.
  var path_606424 = newJObject()
  var body_606425 = newJObject()
  if body != nil:
    body_606425 = body
  add(path_606424, "Id", newJString(Id))
  result = call_606423.call(path_606424, nil, nil, nil, body_606425)

var createTrafficPolicyVersion* = Call_CreateTrafficPolicyVersion_606410(
    name: "createTrafficPolicyVersion", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicy/{Id}",
    validator: validate_CreateTrafficPolicyVersion_606411, base: "/",
    url: url_CreateTrafficPolicyVersion_606412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateVPCAssociationAuthorization_606443 = ref object of OpenApiRestCall_605589
proc url_CreateVPCAssociationAuthorization_606445(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateVPCAssociationAuthorization_606444(path: JsonNode;
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
  var valid_606446 = path.getOrDefault("Id")
  valid_606446 = validateParameter(valid_606446, JString, required = true,
                                 default = nil)
  if valid_606446 != nil:
    section.add "Id", valid_606446
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606455: Call_CreateVPCAssociationAuthorization_606443;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ## 
  let valid = call_606455.validator(path, query, header, formData, body)
  let scheme = call_606455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606455.url(scheme.get, call_606455.host, call_606455.base,
                         call_606455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606455, url, valid)

proc call*(call_606456: Call_CreateVPCAssociationAuthorization_606443;
          body: JsonNode; Id: string): Recallable =
  ## createVPCAssociationAuthorization
  ## <p>Authorizes the AWS account that created a specified VPC to submit an <code>AssociateVPCWithHostedZone</code> request to associate the VPC with a specified hosted zone that was created by a different account. To submit a <code>CreateVPCAssociationAuthorization</code> request, you must use the account that created the hosted zone. After you authorize the association, use the account that created the VPC to submit an <code>AssociateVPCWithHostedZone</code> request.</p> <note> <p>If you want to associate multiple VPCs that you created by using one account with a hosted zone that you created by using a different account, you must submit one authorization request for each VPC.</p> </note>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to authorize associating a VPC with.
  var path_606457 = newJObject()
  var body_606458 = newJObject()
  if body != nil:
    body_606458 = body
  add(path_606457, "Id", newJString(Id))
  result = call_606456.call(path_606457, nil, nil, nil, body_606458)

var createVPCAssociationAuthorization* = Call_CreateVPCAssociationAuthorization_606443(
    name: "createVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_CreateVPCAssociationAuthorization_606444, base: "/",
    url: url_CreateVPCAssociationAuthorization_606445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVPCAssociationAuthorizations_606426 = ref object of OpenApiRestCall_605589
proc url_ListVPCAssociationAuthorizations_606428(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVPCAssociationAuthorizations_606427(path: JsonNode;
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
  var valid_606429 = path.getOrDefault("Id")
  valid_606429 = validateParameter(valid_606429, JString, required = true,
                                 default = nil)
  if valid_606429 != nil:
    section.add "Id", valid_606429
  result.add "path", section
  ## parameters in `query` object:
  ##   nexttoken: JString
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: JString
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  section = newJObject()
  var valid_606430 = query.getOrDefault("nexttoken")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "nexttoken", valid_606430
  var valid_606431 = query.getOrDefault("maxresults")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "maxresults", valid_606431
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

proc call*(call_606439: Call_ListVPCAssociationAuthorizations_606426;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ## 
  let valid = call_606439.validator(path, query, header, formData, body)
  let scheme = call_606439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606439.url(scheme.get, call_606439.host, call_606439.base,
                         call_606439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606439, url, valid)

proc call*(call_606440: Call_ListVPCAssociationAuthorizations_606426; Id: string;
          nexttoken: string = ""; maxresults: string = ""): Recallable =
  ## listVPCAssociationAuthorizations
  ## <p>Gets a list of the VPCs that were created by other accounts and that can be associated with a specified hosted zone because you've submitted one or more <code>CreateVPCAssociationAuthorization</code> requests. </p> <p>The response includes a <code>VPCs</code> element with a <code>VPC</code> child element for each VPC that can be associated with the hosted zone.</p>
  ##   nexttoken: string
  ##            :  <i>Optional</i>: If a response includes a <code>NextToken</code> element, there are more VPCs that can be associated with the specified hosted zone. To get the next page of results, submit another request, and include the value of <code>NextToken</code> from the response in the <code>nexttoken</code> parameter in another <code>ListVPCAssociationAuthorizations</code> request.
  ##   maxresults: string
  ##             :  <i>Optional</i>: An integer that specifies the maximum number of VPCs that you want Amazon Route 53 to return. If you don't specify a value for <code>MaxResults</code>, Route 53 returns up to 50 VPCs per page.
  ##   Id: string (required)
  ##     : The ID of the hosted zone for which you want a list of VPCs that can be associated with the hosted zone.
  var path_606441 = newJObject()
  var query_606442 = newJObject()
  add(query_606442, "nexttoken", newJString(nexttoken))
  add(query_606442, "maxresults", newJString(maxresults))
  add(path_606441, "Id", newJString(Id))
  result = call_606440.call(path_606441, query_606442, nil, nil, nil)

var listVPCAssociationAuthorizations* = Call_ListVPCAssociationAuthorizations_606426(
    name: "listVPCAssociationAuthorizations", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/authorizevpcassociation",
    validator: validate_ListVPCAssociationAuthorizations_606427, base: "/",
    url: url_ListVPCAssociationAuthorizations_606428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHealthCheck_606473 = ref object of OpenApiRestCall_605589
proc url_UpdateHealthCheck_606475(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateHealthCheck_606474(path: JsonNode; query: JsonNode;
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
  var valid_606476 = path.getOrDefault("HealthCheckId")
  valid_606476 = validateParameter(valid_606476, JString, required = true,
                                 default = nil)
  if valid_606476 != nil:
    section.add "HealthCheckId", valid_606476
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
  var valid_606477 = header.getOrDefault("X-Amz-Signature")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Signature", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Content-Sha256", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Date")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Date", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Credential")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Credential", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Security-Token")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Security-Token", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Algorithm")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Algorithm", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-SignedHeaders", valid_606483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606485: Call_UpdateHealthCheck_606473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ## 
  let valid = call_606485.validator(path, query, header, formData, body)
  let scheme = call_606485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606485.url(scheme.get, call_606485.host, call_606485.base,
                         call_606485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606485, url, valid)

proc call*(call_606486: Call_UpdateHealthCheck_606473; HealthCheckId: string;
          body: JsonNode): Recallable =
  ## updateHealthCheck
  ## <p>Updates an existing health check. Note that some values can't be updated. </p> <p>For more information about updating health checks, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html">Creating, Updating, and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p>
  ##   HealthCheckId: string (required)
  ##                : The ID for the health check for which you want detailed information. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.
  ##   body: JObject (required)
  var path_606487 = newJObject()
  var body_606488 = newJObject()
  add(path_606487, "HealthCheckId", newJString(HealthCheckId))
  if body != nil:
    body_606488 = body
  result = call_606486.call(path_606487, nil, nil, nil, body_606488)

var updateHealthCheck* = Call_UpdateHealthCheck_606473(name: "updateHealthCheck",
    meth: HttpMethod.HttpPost, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_UpdateHealthCheck_606474, base: "/",
    url: url_UpdateHealthCheck_606475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheck_606459 = ref object of OpenApiRestCall_605589
proc url_GetHealthCheck_606461(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheck_606460(path: JsonNode; query: JsonNode;
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
  var valid_606462 = path.getOrDefault("HealthCheckId")
  valid_606462 = validateParameter(valid_606462, JString, required = true,
                                 default = nil)
  if valid_606462 != nil:
    section.add "HealthCheckId", valid_606462
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
  var valid_606463 = header.getOrDefault("X-Amz-Signature")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Signature", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Content-Sha256", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Date")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Date", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Credential")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Credential", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Security-Token")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Security-Token", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Algorithm")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Algorithm", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-SignedHeaders", valid_606469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606470: Call_GetHealthCheck_606459; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified health check.
  ## 
  let valid = call_606470.validator(path, query, header, formData, body)
  let scheme = call_606470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606470.url(scheme.get, call_606470.host, call_606470.base,
                         call_606470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606470, url, valid)

proc call*(call_606471: Call_GetHealthCheck_606459; HealthCheckId: string): Recallable =
  ## getHealthCheck
  ## Gets information about a specified health check.
  ##   HealthCheckId: string (required)
  ##                : The identifier that Amazon Route 53 assigned to the health check when you created it. When you add or update a resource record set, you use this value to specify which health check to use. The value can be up to 64 characters long.
  var path_606472 = newJObject()
  add(path_606472, "HealthCheckId", newJString(HealthCheckId))
  result = call_606471.call(path_606472, nil, nil, nil, nil)

var getHealthCheck* = Call_GetHealthCheck_606459(name: "getHealthCheck",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_GetHealthCheck_606460, base: "/", url: url_GetHealthCheck_606461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHealthCheck_606489 = ref object of OpenApiRestCall_605589
proc url_DeleteHealthCheck_606491(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHealthCheck_606490(path: JsonNode; query: JsonNode;
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
  var valid_606492 = path.getOrDefault("HealthCheckId")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = nil)
  if valid_606492 != nil:
    section.add "HealthCheckId", valid_606492
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

proc call*(call_606500: Call_DeleteHealthCheck_606489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_606500.validator(path, query, header, formData, body)
  let scheme = call_606500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606500.url(scheme.get, call_606500.host, call_606500.base,
                         call_606500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606500, url, valid)

proc call*(call_606501: Call_DeleteHealthCheck_606489; HealthCheckId: string): Recallable =
  ## deleteHealthCheck
  ## <p>Deletes a health check.</p> <important> <p>Amazon Route 53 does not prevent you from deleting a health check even if the health check is associated with one or more resource record sets. If you delete a health check and you don't update the associated resource record sets, the future status of the health check can't be predicted and may change. This will affect the routing of DNS queries for your DNS failover configuration. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-deleting.html#health-checks-deleting.html">Replacing and Deleting Health Checks</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ##   HealthCheckId: string (required)
  ##                : The ID of the health check that you want to delete.
  var path_606502 = newJObject()
  add(path_606502, "HealthCheckId", newJString(HealthCheckId))
  result = call_606501.call(path_606502, nil, nil, nil, nil)

var deleteHealthCheck* = Call_DeleteHealthCheck_606489(name: "deleteHealthCheck",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}",
    validator: validate_DeleteHealthCheck_606490, base: "/",
    url: url_DeleteHealthCheck_606491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateHostedZoneComment_606517 = ref object of OpenApiRestCall_605589
proc url_UpdateHostedZoneComment_606519(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateHostedZoneComment_606518(path: JsonNode; query: JsonNode;
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
  var valid_606520 = path.getOrDefault("Id")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = nil)
  if valid_606520 != nil:
    section.add "Id", valid_606520
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606529: Call_UpdateHostedZoneComment_606517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified hosted zone.
  ## 
  let valid = call_606529.validator(path, query, header, formData, body)
  let scheme = call_606529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606529.url(scheme.get, call_606529.host, call_606529.base,
                         call_606529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606529, url, valid)

proc call*(call_606530: Call_UpdateHostedZoneComment_606517; body: JsonNode;
          Id: string): Recallable =
  ## updateHostedZoneComment
  ## Updates the comment for a specified hosted zone.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID for the hosted zone that you want to update the comment for.
  var path_606531 = newJObject()
  var body_606532 = newJObject()
  if body != nil:
    body_606532 = body
  add(path_606531, "Id", newJString(Id))
  result = call_606530.call(path_606531, nil, nil, nil, body_606532)

var updateHostedZoneComment* = Call_UpdateHostedZoneComment_606517(
    name: "updateHostedZoneComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}",
    validator: validate_UpdateHostedZoneComment_606518, base: "/",
    url: url_UpdateHostedZoneComment_606519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZone_606503 = ref object of OpenApiRestCall_605589
proc url_GetHostedZone_606505(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHostedZone_606504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606506 = path.getOrDefault("Id")
  valid_606506 = validateParameter(valid_606506, JString, required = true,
                                 default = nil)
  if valid_606506 != nil:
    section.add "Id", valid_606506
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

proc call*(call_606514: Call_GetHostedZone_606503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ## 
  let valid = call_606514.validator(path, query, header, formData, body)
  let scheme = call_606514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606514.url(scheme.get, call_606514.host, call_606514.base,
                         call_606514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606514, url, valid)

proc call*(call_606515: Call_GetHostedZone_606503; Id: string): Recallable =
  ## getHostedZone
  ## Gets information about a specified hosted zone including the four name servers assigned to the hosted zone.
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get information about.
  var path_606516 = newJObject()
  add(path_606516, "Id", newJString(Id))
  result = call_606515.call(path_606516, nil, nil, nil, nil)

var getHostedZone* = Call_GetHostedZone_606503(name: "getHostedZone",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_GetHostedZone_606504,
    base: "/", url: url_GetHostedZone_606505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHostedZone_606533 = ref object of OpenApiRestCall_605589
proc url_DeleteHostedZone_606535(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHostedZone_606534(path: JsonNode; query: JsonNode;
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
  var valid_606536 = path.getOrDefault("Id")
  valid_606536 = validateParameter(valid_606536, JString, required = true,
                                 default = nil)
  if valid_606536 != nil:
    section.add "Id", valid_606536
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
  var valid_606537 = header.getOrDefault("X-Amz-Signature")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Signature", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Content-Sha256", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Date")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Date", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Credential")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Credential", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Security-Token")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Security-Token", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Algorithm")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Algorithm", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-SignedHeaders", valid_606543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606544: Call_DeleteHostedZone_606533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ## 
  let valid = call_606544.validator(path, query, header, formData, body)
  let scheme = call_606544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606544.url(scheme.get, call_606544.host, call_606544.base,
                         call_606544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606544, url, valid)

proc call*(call_606545: Call_DeleteHostedZone_606533; Id: string): Recallable =
  ## deleteHostedZone
  ## <p>Deletes a hosted zone.</p> <p>If the hosted zone was created by another service, such as AWS Cloud Map, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DeleteHostedZone.html#delete-public-hosted-zone-created-by-another-service">Deleting Public Hosted Zones That Were Created by Another Service</a> in the <i>Amazon Route 53 Developer Guide</i> for information about how to delete it. (The process is the same for public and private hosted zones that were created by another service.)</p> <p>If you want to keep your domain registration but you want to stop routing internet traffic to your website or web application, we recommend that you delete resource record sets in the hosted zone instead of deleting the hosted zone.</p> <important> <p>If you delete a hosted zone, you can't undelete it. You must create a new hosted zone and update the name servers for your domain registration, which can require up to 48 hours to take effect. (If you delegated responsibility for a subdomain to a hosted zone and you delete the child hosted zone, you must update the name servers in the parent hosted zone.) In addition, if you delete a hosted zone, someone could hijack the domain and route traffic to their own resources using your domain name.</p> </important> <p>If you want to avoid the monthly charge for the hosted zone, you can transfer DNS service for the domain to a free DNS service. When you transfer DNS service, you have to update the name servers for the domain registration. If the domain is registered with Route 53, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_domains_UpdateDomainNameservers.html">UpdateDomainNameservers</a> for information about how to replace Route 53 name servers with name servers for the new DNS service. If the domain is registered with another registrar, use the method provided by the registrar to update name servers for the domain registration. For more information, perform an internet search on "free DNS service."</p> <p>You can delete a hosted zone only if it contains only the default SOA record and NS resource record sets. If the hosted zone contains other resource record sets, you must delete them before you can delete the hosted zone. If you try to delete a hosted zone that contains other resource record sets, the request fails, and Route 53 returns a <code>HostedZoneNotEmpty</code> error. For information about deleting records from your hosted zone, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html">ChangeResourceRecordSets</a>.</p> <p>To verify that the hosted zone has been deleted, do one of the following:</p> <ul> <li> <p>Use the <code>GetHostedZone</code> action to request information about the hosted zone.</p> </li> <li> <p>Use the <code>ListHostedZones</code> action to get a list of the hosted zones associated with the current AWS account.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone you want to delete.
  var path_606546 = newJObject()
  add(path_606546, "Id", newJString(Id))
  result = call_606545.call(path_606546, nil, nil, nil, nil)

var deleteHostedZone* = Call_DeleteHostedZone_606533(name: "deleteHostedZone",
    meth: HttpMethod.HttpDelete, host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}", validator: validate_DeleteHostedZone_606534,
    base: "/", url: url_DeleteHostedZone_606535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetQueryLoggingConfig_606547 = ref object of OpenApiRestCall_605589
proc url_GetQueryLoggingConfig_606549(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetQueryLoggingConfig_606548(path: JsonNode; query: JsonNode;
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
  var valid_606550 = path.getOrDefault("Id")
  valid_606550 = validateParameter(valid_606550, JString, required = true,
                                 default = nil)
  if valid_606550 != nil:
    section.add "Id", valid_606550
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
  var valid_606551 = header.getOrDefault("X-Amz-Signature")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Signature", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Content-Sha256", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Date")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Date", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Credential")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Credential", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Security-Token")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Security-Token", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Algorithm")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Algorithm", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-SignedHeaders", valid_606557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606558: Call_GetQueryLoggingConfig_606547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ## 
  let valid = call_606558.validator(path, query, header, formData, body)
  let scheme = call_606558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606558.url(scheme.get, call_606558.host, call_606558.base,
                         call_606558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606558, url, valid)

proc call*(call_606559: Call_GetQueryLoggingConfig_606547; Id: string): Recallable =
  ## getQueryLoggingConfig
  ## <p>Gets information about a specified configuration for DNS query logging.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a> and <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/query-logs.html">Logging DNS Queries</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration for DNS query logging that you want to get information about.
  var path_606560 = newJObject()
  add(path_606560, "Id", newJString(Id))
  result = call_606559.call(path_606560, nil, nil, nil, nil)

var getQueryLoggingConfig* = Call_GetQueryLoggingConfig_606547(
    name: "getQueryLoggingConfig", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_GetQueryLoggingConfig_606548, base: "/",
    url: url_GetQueryLoggingConfig_606549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteQueryLoggingConfig_606561 = ref object of OpenApiRestCall_605589
proc url_DeleteQueryLoggingConfig_606563(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteQueryLoggingConfig_606562(path: JsonNode; query: JsonNode;
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
  var valid_606564 = path.getOrDefault("Id")
  valid_606564 = validateParameter(valid_606564, JString, required = true,
                                 default = nil)
  if valid_606564 != nil:
    section.add "Id", valid_606564
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
  var valid_606565 = header.getOrDefault("X-Amz-Signature")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Signature", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Content-Sha256", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Date")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Date", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Credential")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Credential", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Security-Token")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Security-Token", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Algorithm")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Algorithm", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-SignedHeaders", valid_606571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606572: Call_DeleteQueryLoggingConfig_606561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ## 
  let valid = call_606572.validator(path, query, header, formData, body)
  let scheme = call_606572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606572.url(scheme.get, call_606572.host, call_606572.base,
                         call_606572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606572, url, valid)

proc call*(call_606573: Call_DeleteQueryLoggingConfig_606561; Id: string): Recallable =
  ## deleteQueryLoggingConfig
  ## <p>Deletes a configuration for DNS query logging. If you delete a configuration, Amazon Route 53 stops sending query logs to CloudWatch Logs. Route 53 doesn't delete any logs that are already in CloudWatch Logs.</p> <p>For more information about DNS query logs, see <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_CreateQueryLoggingConfig.html">CreateQueryLoggingConfig</a>.</p>
  ##   Id: string (required)
  ##     : The ID of the configuration that you want to delete. 
  var path_606574 = newJObject()
  add(path_606574, "Id", newJString(Id))
  result = call_606573.call(path_606574, nil, nil, nil, nil)

var deleteQueryLoggingConfig* = Call_DeleteQueryLoggingConfig_606561(
    name: "deleteQueryLoggingConfig", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/queryloggingconfig/{Id}",
    validator: validate_DeleteQueryLoggingConfig_606562, base: "/",
    url: url_DeleteQueryLoggingConfig_606563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSet_606575 = ref object of OpenApiRestCall_605589
proc url_GetReusableDelegationSet_606577(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetReusableDelegationSet_606576(path: JsonNode; query: JsonNode;
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
  var valid_606578 = path.getOrDefault("Id")
  valid_606578 = validateParameter(valid_606578, JString, required = true,
                                 default = nil)
  if valid_606578 != nil:
    section.add "Id", valid_606578
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
  var valid_606579 = header.getOrDefault("X-Amz-Signature")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Signature", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Content-Sha256", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Date")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Date", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Credential")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Credential", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-Security-Token")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Security-Token", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Algorithm")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Algorithm", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-SignedHeaders", valid_606585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606586: Call_GetReusableDelegationSet_606575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ## 
  let valid = call_606586.validator(path, query, header, formData, body)
  let scheme = call_606586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606586.url(scheme.get, call_606586.host, call_606586.base,
                         call_606586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606586, url, valid)

proc call*(call_606587: Call_GetReusableDelegationSet_606575; Id: string): Recallable =
  ## getReusableDelegationSet
  ## Retrieves information about a specified reusable delegation set, including the four name servers that are assigned to the delegation set.
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to get a list of name servers for.
  var path_606588 = newJObject()
  add(path_606588, "Id", newJString(Id))
  result = call_606587.call(path_606588, nil, nil, nil, nil)

var getReusableDelegationSet* = Call_GetReusableDelegationSet_606575(
    name: "getReusableDelegationSet", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_GetReusableDelegationSet_606576, base: "/",
    url: url_GetReusableDelegationSet_606577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReusableDelegationSet_606589 = ref object of OpenApiRestCall_605589
proc url_DeleteReusableDelegationSet_606591(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteReusableDelegationSet_606590(path: JsonNode; query: JsonNode;
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
  var valid_606592 = path.getOrDefault("Id")
  valid_606592 = validateParameter(valid_606592, JString, required = true,
                                 default = nil)
  if valid_606592 != nil:
    section.add "Id", valid_606592
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
  var valid_606593 = header.getOrDefault("X-Amz-Signature")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Signature", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Content-Sha256", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Date")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Date", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Credential")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Credential", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Security-Token")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Security-Token", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Algorithm")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Algorithm", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-SignedHeaders", valid_606599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606600: Call_DeleteReusableDelegationSet_606589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ## 
  let valid = call_606600.validator(path, query, header, formData, body)
  let scheme = call_606600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606600.url(scheme.get, call_606600.host, call_606600.base,
                         call_606600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606600, url, valid)

proc call*(call_606601: Call_DeleteReusableDelegationSet_606589; Id: string): Recallable =
  ## deleteReusableDelegationSet
  ## <p>Deletes a reusable delegation set.</p> <important> <p>You can delete a reusable delegation set only if it isn't associated with any hosted zones.</p> </important> <p>To verify that the reusable delegation set is not associated with any hosted zones, submit a <a href="https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetReusableDelegationSet.html">GetReusableDelegationSet</a> request and specify the ID of the reusable delegation set that you want to delete.</p>
  ##   Id: string (required)
  ##     : The ID of the reusable delegation set that you want to delete.
  var path_606602 = newJObject()
  add(path_606602, "Id", newJString(Id))
  result = call_606601.call(path_606602, nil, nil, nil, nil)

var deleteReusableDelegationSet* = Call_DeleteReusableDelegationSet_606589(
    name: "deleteReusableDelegationSet", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com", route: "/2013-04-01/delegationset/{Id}",
    validator: validate_DeleteReusableDelegationSet_606590, base: "/",
    url: url_DeleteReusableDelegationSet_606591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyComment_606618 = ref object of OpenApiRestCall_605589
proc url_UpdateTrafficPolicyComment_606620(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyComment_606619(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the comment for a specified traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   Id: JString (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_606621 = path.getOrDefault("Version")
  valid_606621 = validateParameter(valid_606621, JInt, required = true, default = nil)
  if valid_606621 != nil:
    section.add "Version", valid_606621
  var valid_606622 = path.getOrDefault("Id")
  valid_606622 = validateParameter(valid_606622, JString, required = true,
                                 default = nil)
  if valid_606622 != nil:
    section.add "Id", valid_606622
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
  var valid_606623 = header.getOrDefault("X-Amz-Signature")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Signature", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Content-Sha256", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Date")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Date", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Credential")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Credential", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Security-Token")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Security-Token", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Algorithm")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Algorithm", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-SignedHeaders", valid_606629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606631: Call_UpdateTrafficPolicyComment_606618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the comment for a specified traffic policy version.
  ## 
  let valid = call_606631.validator(path, query, header, formData, body)
  let scheme = call_606631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606631.url(scheme.get, call_606631.host, call_606631.base,
                         call_606631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606631, url, valid)

proc call*(call_606632: Call_UpdateTrafficPolicyComment_606618; Version: int;
          body: JsonNode; Id: string): Recallable =
  ## updateTrafficPolicyComment
  ## Updates the comment for a specified traffic policy version.
  ##   Version: int (required)
  ##          : The value of <code>Version</code> for the traffic policy that you want to update the comment for.
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The value of <code>Id</code> for the traffic policy that you want to update the comment for.
  var path_606633 = newJObject()
  var body_606634 = newJObject()
  add(path_606633, "Version", newJInt(Version))
  if body != nil:
    body_606634 = body
  add(path_606633, "Id", newJString(Id))
  result = call_606632.call(path_606633, nil, nil, nil, body_606634)

var updateTrafficPolicyComment* = Call_UpdateTrafficPolicyComment_606618(
    name: "updateTrafficPolicyComment", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_UpdateTrafficPolicyComment_606619, base: "/",
    url: url_UpdateTrafficPolicyComment_606620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicy_606603 = ref object of OpenApiRestCall_605589
proc url_GetTrafficPolicy_606605(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTrafficPolicy_606604(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about a specific traffic policy version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to get information about.
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to get information about.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_606606 = path.getOrDefault("Version")
  valid_606606 = validateParameter(valid_606606, JInt, required = true, default = nil)
  if valid_606606 != nil:
    section.add "Version", valid_606606
  var valid_606607 = path.getOrDefault("Id")
  valid_606607 = validateParameter(valid_606607, JString, required = true,
                                 default = nil)
  if valid_606607 != nil:
    section.add "Id", valid_606607
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
  var valid_606608 = header.getOrDefault("X-Amz-Signature")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Signature", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Content-Sha256", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Date")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Date", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Credential")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Credential", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Security-Token")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Security-Token", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Algorithm")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Algorithm", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-SignedHeaders", valid_606614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606615: Call_GetTrafficPolicy_606603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific traffic policy version.
  ## 
  let valid = call_606615.validator(path, query, header, formData, body)
  let scheme = call_606615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606615.url(scheme.get, call_606615.host, call_606615.base,
                         call_606615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606615, url, valid)

proc call*(call_606616: Call_GetTrafficPolicy_606603; Version: int; Id: string): Recallable =
  ## getTrafficPolicy
  ## Gets information about a specific traffic policy version.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to get information about.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to get information about.
  var path_606617 = newJObject()
  add(path_606617, "Version", newJInt(Version))
  add(path_606617, "Id", newJString(Id))
  result = call_606616.call(path_606617, nil, nil, nil, nil)

var getTrafficPolicy* = Call_GetTrafficPolicy_606603(name: "getTrafficPolicy",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_GetTrafficPolicy_606604, base: "/",
    url: url_GetTrafficPolicy_606605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicy_606635 = ref object of OpenApiRestCall_605589
proc url_DeleteTrafficPolicy_606637(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTrafficPolicy_606636(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes a traffic policy.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Version: JInt (required)
  ##          : The version number of the traffic policy that you want to delete.
  ##   Id: JString (required)
  ##     : The ID of the traffic policy that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Version` field"
  var valid_606638 = path.getOrDefault("Version")
  valid_606638 = validateParameter(valid_606638, JInt, required = true, default = nil)
  if valid_606638 != nil:
    section.add "Version", valid_606638
  var valid_606639 = path.getOrDefault("Id")
  valid_606639 = validateParameter(valid_606639, JString, required = true,
                                 default = nil)
  if valid_606639 != nil:
    section.add "Id", valid_606639
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
  var valid_606640 = header.getOrDefault("X-Amz-Signature")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Signature", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Content-Sha256", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Date")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Date", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Credential")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Credential", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Security-Token")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Security-Token", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Algorithm")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Algorithm", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-SignedHeaders", valid_606646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606647: Call_DeleteTrafficPolicy_606635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a traffic policy.
  ## 
  let valid = call_606647.validator(path, query, header, formData, body)
  let scheme = call_606647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606647.url(scheme.get, call_606647.host, call_606647.base,
                         call_606647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606647, url, valid)

proc call*(call_606648: Call_DeleteTrafficPolicy_606635; Version: int; Id: string): Recallable =
  ## deleteTrafficPolicy
  ## Deletes a traffic policy.
  ##   Version: int (required)
  ##          : The version number of the traffic policy that you want to delete.
  ##   Id: string (required)
  ##     : The ID of the traffic policy that you want to delete.
  var path_606649 = newJObject()
  add(path_606649, "Version", newJInt(Version))
  add(path_606649, "Id", newJString(Id))
  result = call_606648.call(path_606649, nil, nil, nil, nil)

var deleteTrafficPolicy* = Call_DeleteTrafficPolicy_606635(
    name: "deleteTrafficPolicy", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicy/{Id}/{Version}",
    validator: validate_DeleteTrafficPolicy_606636, base: "/",
    url: url_DeleteTrafficPolicy_606637, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrafficPolicyInstance_606664 = ref object of OpenApiRestCall_605589
proc url_UpdateTrafficPolicyInstance_606666(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTrafficPolicyInstance_606665(path: JsonNode; query: JsonNode;
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
  var valid_606667 = path.getOrDefault("Id")
  valid_606667 = validateParameter(valid_606667, JString, required = true,
                                 default = nil)
  if valid_606667 != nil:
    section.add "Id", valid_606667
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
  var valid_606668 = header.getOrDefault("X-Amz-Signature")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Signature", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Content-Sha256", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Date")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Date", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Credential")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Credential", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Security-Token")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Security-Token", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Algorithm")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Algorithm", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-SignedHeaders", valid_606674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606676: Call_UpdateTrafficPolicyInstance_606664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ## 
  let valid = call_606676.validator(path, query, header, formData, body)
  let scheme = call_606676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606676.url(scheme.get, call_606676.host, call_606676.base,
                         call_606676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606676, url, valid)

proc call*(call_606677: Call_UpdateTrafficPolicyInstance_606664; body: JsonNode;
          Id: string): Recallable =
  ## updateTrafficPolicyInstance
  ## <p>Updates the resource record sets in a specified hosted zone that were created based on the settings in a specified traffic policy version.</p> <p>When you update a traffic policy instance, Amazon Route 53 continues to respond to DNS queries for the root resource record set name (such as example.com) while it replaces one group of resource record sets with another. Route 53 performs the following operations:</p> <ol> <li> <p>Route 53 creates a new group of resource record sets based on the specified traffic policy. This is true regardless of how significant the differences are between the existing resource record sets and the new resource record sets. </p> </li> <li> <p>When all of the new resource record sets have been created, Route 53 starts to respond to DNS queries for the root resource record set name (such as example.com) by using the new resource record sets.</p> </li> <li> <p>Route 53 deletes the old group of resource record sets that are associated with the root resource record set name.</p> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to update.
  var path_606678 = newJObject()
  var body_606679 = newJObject()
  if body != nil:
    body_606679 = body
  add(path_606678, "Id", newJString(Id))
  result = call_606677.call(path_606678, nil, nil, nil, body_606679)

var updateTrafficPolicyInstance* = Call_UpdateTrafficPolicyInstance_606664(
    name: "updateTrafficPolicyInstance", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_UpdateTrafficPolicyInstance_606665, base: "/",
    url: url_UpdateTrafficPolicyInstance_606666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstance_606650 = ref object of OpenApiRestCall_605589
proc url_GetTrafficPolicyInstance_606652(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetTrafficPolicyInstance_606651(path: JsonNode; query: JsonNode;
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
  var valid_606653 = path.getOrDefault("Id")
  valid_606653 = validateParameter(valid_606653, JString, required = true,
                                 default = nil)
  if valid_606653 != nil:
    section.add "Id", valid_606653
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
  var valid_606654 = header.getOrDefault("X-Amz-Signature")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Signature", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Content-Sha256", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Date")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Date", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Credential")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Credential", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Security-Token")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Security-Token", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Algorithm")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Algorithm", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-SignedHeaders", valid_606660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606661: Call_GetTrafficPolicyInstance_606650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_606661.validator(path, query, header, formData, body)
  let scheme = call_606661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606661.url(scheme.get, call_606661.host, call_606661.base,
                         call_606661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606661, url, valid)

proc call*(call_606662: Call_GetTrafficPolicyInstance_606650; Id: string): Recallable =
  ## getTrafficPolicyInstance
  ## <p>Gets information about a specified traffic policy instance.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : The ID of the traffic policy instance that you want to get information about.
  var path_606663 = newJObject()
  add(path_606663, "Id", newJString(Id))
  result = call_606662.call(path_606663, nil, nil, nil, nil)

var getTrafficPolicyInstance* = Call_GetTrafficPolicyInstance_606650(
    name: "getTrafficPolicyInstance", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_GetTrafficPolicyInstance_606651, base: "/",
    url: url_GetTrafficPolicyInstance_606652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrafficPolicyInstance_606680 = ref object of OpenApiRestCall_605589
proc url_DeleteTrafficPolicyInstance_606682(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTrafficPolicyInstance_606681(path: JsonNode; query: JsonNode;
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
  var valid_606683 = path.getOrDefault("Id")
  valid_606683 = validateParameter(valid_606683, JString, required = true,
                                 default = nil)
  if valid_606683 != nil:
    section.add "Id", valid_606683
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
  var valid_606684 = header.getOrDefault("X-Amz-Signature")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Signature", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Content-Sha256", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Date")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Date", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Credential")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Credential", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Security-Token")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Security-Token", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Algorithm")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Algorithm", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-SignedHeaders", valid_606690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606691: Call_DeleteTrafficPolicyInstance_606680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ## 
  let valid = call_606691.validator(path, query, header, formData, body)
  let scheme = call_606691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606691.url(scheme.get, call_606691.host, call_606691.base,
                         call_606691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606691, url, valid)

proc call*(call_606692: Call_DeleteTrafficPolicyInstance_606680; Id: string): Recallable =
  ## deleteTrafficPolicyInstance
  ## <p>Deletes a traffic policy instance and all of the resource record sets that Amazon Route 53 created when you created the instance.</p> <note> <p>In the Route 53 console, traffic policy instances are known as policy records.</p> </note>
  ##   Id: string (required)
  ##     : <p>The ID of the traffic policy instance that you want to delete. </p> <important> <p>When you delete a traffic policy instance, Amazon Route 53 also deletes all of the resource record sets that were created when you created the traffic policy instance.</p> </important>
  var path_606693 = newJObject()
  add(path_606693, "Id", newJString(Id))
  result = call_606692.call(path_606693, nil, nil, nil, nil)

var deleteTrafficPolicyInstance* = Call_DeleteTrafficPolicyInstance_606680(
    name: "deleteTrafficPolicyInstance", meth: HttpMethod.HttpDelete,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstance/{Id}",
    validator: validate_DeleteTrafficPolicyInstance_606681, base: "/",
    url: url_DeleteTrafficPolicyInstance_606682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteVPCAssociationAuthorization_606694 = ref object of OpenApiRestCall_605589
proc url_DeleteVPCAssociationAuthorization_606696(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteVPCAssociationAuthorization_606695(path: JsonNode;
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
  var valid_606697 = path.getOrDefault("Id")
  valid_606697 = validateParameter(valid_606697, JString, required = true,
                                 default = nil)
  if valid_606697 != nil:
    section.add "Id", valid_606697
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
  var valid_606698 = header.getOrDefault("X-Amz-Signature")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Signature", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Content-Sha256", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Date")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Date", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Credential")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Credential", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Security-Token")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Security-Token", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Algorithm")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Algorithm", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-SignedHeaders", valid_606704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606706: Call_DeleteVPCAssociationAuthorization_606694;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ## 
  let valid = call_606706.validator(path, query, header, formData, body)
  let scheme = call_606706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606706.url(scheme.get, call_606706.host, call_606706.base,
                         call_606706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606706, url, valid)

proc call*(call_606707: Call_DeleteVPCAssociationAuthorization_606694;
          body: JsonNode; Id: string): Recallable =
  ## deleteVPCAssociationAuthorization
  ## <p>Removes authorization to submit an <code>AssociateVPCWithHostedZone</code> request to associate a specified VPC with a hosted zone that was created by a different account. You must use the account that created the hosted zone to submit a <code>DeleteVPCAssociationAuthorization</code> request.</p> <important> <p>Sending this request only prevents the AWS account that created the VPC from associating the VPC with the Amazon Route 53 hosted zone in the future. If the VPC is already associated with the hosted zone, <code>DeleteVPCAssociationAuthorization</code> won't disassociate the VPC from the hosted zone. If you want to delete an existing association, use <code>DisassociateVPCFromHostedZone</code>.</p> </important>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : When removing authorization to associate a VPC that was created by one AWS account with a hosted zone that was created with a different AWS account, the ID of the hosted zone.
  var path_606708 = newJObject()
  var body_606709 = newJObject()
  if body != nil:
    body_606709 = body
  add(path_606708, "Id", newJString(Id))
  result = call_606707.call(path_606708, nil, nil, nil, body_606709)

var deleteVPCAssociationAuthorization* = Call_DeleteVPCAssociationAuthorization_606694(
    name: "deleteVPCAssociationAuthorization", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/deauthorizevpcassociation",
    validator: validate_DeleteVPCAssociationAuthorization_606695, base: "/",
    url: url_DeleteVPCAssociationAuthorization_606696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateVPCFromHostedZone_606710 = ref object of OpenApiRestCall_605589
proc url_DisassociateVPCFromHostedZone_606712(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateVPCFromHostedZone_606711(path: JsonNode; query: JsonNode;
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
  var valid_606713 = path.getOrDefault("Id")
  valid_606713 = validateParameter(valid_606713, JString, required = true,
                                 default = nil)
  if valid_606713 != nil:
    section.add "Id", valid_606713
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
  var valid_606714 = header.getOrDefault("X-Amz-Signature")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Signature", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Content-Sha256", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Date")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Date", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Credential")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Credential", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Security-Token")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Security-Token", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Algorithm")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Algorithm", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-SignedHeaders", valid_606720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606722: Call_DisassociateVPCFromHostedZone_606710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ## 
  let valid = call_606722.validator(path, query, header, formData, body)
  let scheme = call_606722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606722.url(scheme.get, call_606722.host, call_606722.base,
                         call_606722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606722, url, valid)

proc call*(call_606723: Call_DisassociateVPCFromHostedZone_606710; body: JsonNode;
          Id: string): Recallable =
  ## disassociateVPCFromHostedZone
  ## <p>Disassociates a VPC from a Amazon Route 53 private hosted zone. Note the following:</p> <ul> <li> <p>You can't disassociate the last VPC from a private hosted zone.</p> </li> <li> <p>You can't convert a private hosted zone into a public hosted zone.</p> </li> <li> <p>You can submit a <code>DisassociateVPCFromHostedZone</code> request using either the account that created the hosted zone or the account that created the VPC.</p> </li> </ul>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The ID of the private hosted zone that you want to disassociate a VPC from.
  var path_606724 = newJObject()
  var body_606725 = newJObject()
  if body != nil:
    body_606725 = body
  add(path_606724, "Id", newJString(Id))
  result = call_606723.call(path_606724, nil, nil, nil, body_606725)

var disassociateVPCFromHostedZone* = Call_DisassociateVPCFromHostedZone_606710(
    name: "disassociateVPCFromHostedZone", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzone/{Id}/disassociatevpc",
    validator: validate_DisassociateVPCFromHostedZone_606711, base: "/",
    url: url_DisassociateVPCFromHostedZone_606712,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountLimit_606726 = ref object of OpenApiRestCall_605589
proc url_GetAccountLimit_606728(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAccountLimit_606727(path: JsonNode; query: JsonNode;
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
  var valid_606729 = path.getOrDefault("Type")
  valid_606729 = validateParameter(valid_606729, JString, required = true, default = newJString(
      "MAX_HEALTH_CHECKS_BY_OWNER"))
  if valid_606729 != nil:
    section.add "Type", valid_606729
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
  var valid_606730 = header.getOrDefault("X-Amz-Signature")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Signature", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Content-Sha256", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Date")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Date", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Credential")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Credential", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Security-Token")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Security-Token", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Algorithm")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Algorithm", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-SignedHeaders", valid_606736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606737: Call_GetAccountLimit_606726; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ## 
  let valid = call_606737.validator(path, query, header, formData, body)
  let scheme = call_606737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606737.url(scheme.get, call_606737.host, call_606737.base,
                         call_606737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606737, url, valid)

proc call*(call_606738: Call_GetAccountLimit_606726;
          Type: string = "MAX_HEALTH_CHECKS_BY_OWNER"): Recallable =
  ## getAccountLimit
  ## <p>Gets the specified limit for the current account, for example, the maximum number of health checks that you can create using the account.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p> <note> <p>You can also view account limits in AWS Trusted Advisor. Sign in to the AWS Management Console and open the Trusted Advisor console at <a href="https://console.aws.amazon.com/trustedadvisor">https://console.aws.amazon.com/trustedadvisor/</a>. Then choose <b>Service limits</b> in the navigation pane.</p> </note>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_HEALTH_CHECKS_BY_OWNER</b>: The maximum number of health checks that you can create using the current account.</p> </li> <li> <p> <b>MAX_HOSTED_ZONES_BY_OWNER</b>: The maximum number of hosted zones that you can create using the current account.</p> </li> <li> <p> <b>MAX_REUSABLE_DELEGATION_SETS_BY_OWNER</b>: The maximum number of reusable delegation sets that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICIES_BY_OWNER</b>: The maximum number of traffic policies that you can create using the current account.</p> </li> <li> <p> <b>MAX_TRAFFIC_POLICY_INSTANCES_BY_OWNER</b>: The maximum number of traffic policy instances that you can create using the current account. (Traffic policy instances are referred to as traffic flow policy records in the Amazon Route 53 console.)</p> </li> </ul>
  var path_606739 = newJObject()
  add(path_606739, "Type", newJString(Type))
  result = call_606738.call(path_606739, nil, nil, nil, nil)

var getAccountLimit* = Call_GetAccountLimit_606726(name: "getAccountLimit",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/accountlimit/{Type}", validator: validate_GetAccountLimit_606727,
    base: "/", url: url_GetAccountLimit_606728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChange_606740 = ref object of OpenApiRestCall_605589
proc url_GetChange_606742(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetChange_606741(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606743 = path.getOrDefault("Id")
  valid_606743 = validateParameter(valid_606743, JString, required = true,
                                 default = nil)
  if valid_606743 != nil:
    section.add "Id", valid_606743
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
  var valid_606744 = header.getOrDefault("X-Amz-Signature")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Signature", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Content-Sha256", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Date")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Date", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Credential")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Credential", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Security-Token")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Security-Token", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Algorithm")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Algorithm", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-SignedHeaders", valid_606750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606751: Call_GetChange_606740; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ## 
  let valid = call_606751.validator(path, query, header, formData, body)
  let scheme = call_606751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606751.url(scheme.get, call_606751.host, call_606751.base,
                         call_606751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606751, url, valid)

proc call*(call_606752: Call_GetChange_606740; Id: string): Recallable =
  ## getChange
  ## <p>Returns the current status of a change batch request. The status is one of the following values:</p> <ul> <li> <p> <code>PENDING</code> indicates that the changes in this request have not propagated to all Amazon Route 53 DNS servers. This is the initial status of all change batch requests.</p> </li> <li> <p> <code>INSYNC</code> indicates that the changes have propagated to all Route 53 DNS servers. </p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the change batch request. The value that you specify here is the value that <code>ChangeResourceRecordSets</code> returned in the <code>Id</code> element when you submitted the request.
  var path_606753 = newJObject()
  add(path_606753, "Id", newJString(Id))
  result = call_606752.call(path_606753, nil, nil, nil, nil)

var getChange* = Call_GetChange_606740(name: "getChange", meth: HttpMethod.HttpGet,
                                    host: "route53.amazonaws.com",
                                    route: "/2013-04-01/change/{Id}",
                                    validator: validate_GetChange_606741,
                                    base: "/", url: url_GetChange_606742,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckerIpRanges_606754 = ref object of OpenApiRestCall_605589
proc url_GetCheckerIpRanges_606756(protocol: Scheme; host: string; base: string;
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

proc validate_GetCheckerIpRanges_606755(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606757 = header.getOrDefault("X-Amz-Signature")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Signature", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Content-Sha256", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Date")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Date", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Credential")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Credential", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Security-Token")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Security-Token", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Algorithm")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Algorithm", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-SignedHeaders", valid_606763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606764: Call_GetCheckerIpRanges_606754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  ## 
  let valid = call_606764.validator(path, query, header, formData, body)
  let scheme = call_606764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606764.url(scheme.get, call_606764.host, call_606764.base,
                         call_606764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606764, url, valid)

proc call*(call_606765: Call_GetCheckerIpRanges_606754): Recallable =
  ## getCheckerIpRanges
  ## <important> <p> <code>GetCheckerIpRanges</code> still works, but we recommend that you download ip-ranges.json, which includes IP address ranges for all AWS services. For more information, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/route-53-ip-addresses.html">IP Address Ranges of Amazon Route 53 Servers</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> </important>
  result = call_606765.call(nil, nil, nil, nil, nil)

var getCheckerIpRanges* = Call_GetCheckerIpRanges_606754(
    name: "getCheckerIpRanges", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/checkeripranges",
    validator: validate_GetCheckerIpRanges_606755, base: "/",
    url: url_GetCheckerIpRanges_606756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGeoLocation_606766 = ref object of OpenApiRestCall_605589
proc url_GetGeoLocation_606768(protocol: Scheme; host: string; base: string;
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

proc validate_GetGeoLocation_606767(path: JsonNode; query: JsonNode;
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
  var valid_606769 = query.getOrDefault("continentcode")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "continentcode", valid_606769
  var valid_606770 = query.getOrDefault("countrycode")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "countrycode", valid_606770
  var valid_606771 = query.getOrDefault("subdivisioncode")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "subdivisioncode", valid_606771
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
  var valid_606772 = header.getOrDefault("X-Amz-Signature")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Signature", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Content-Sha256", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Date")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Date", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Credential")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Credential", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Security-Token")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Security-Token", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Algorithm")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Algorithm", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-SignedHeaders", valid_606778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606779: Call_GetGeoLocation_606766; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ## 
  let valid = call_606779.validator(path, query, header, formData, body)
  let scheme = call_606779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606779.url(scheme.get, call_606779.host, call_606779.base,
                         call_606779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606779, url, valid)

proc call*(call_606780: Call_GetGeoLocation_606766; continentcode: string = "";
          countrycode: string = ""; subdivisioncode: string = ""): Recallable =
  ## getGeoLocation
  ## <p>Gets information about whether a specified geographic location is supported for Amazon Route 53 geolocation resource record sets.</p> <p>Use the following syntax to determine whether a continent is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?continentcode=<i>two-letter abbreviation for a continent</i> </code> </p> <p>Use the following syntax to determine whether a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i> </code> </p> <p>Use the following syntax to determine whether a subdivision of a country is supported for geolocation:</p> <p> <code>GET /2013-04-01/geolocation?countrycode=<i>two-character country code</i>&amp;subdivisioncode=<i>subdivision code</i> </code> </p>
  ##   continentcode: string
  ##                : <p>Amazon Route 53 supports the following continent codes:</p> <ul> <li> <p> <b>AF</b>: Africa</p> </li> <li> <p> <b>AN</b>: Antarctica</p> </li> <li> <p> <b>AS</b>: Asia</p> </li> <li> <p> <b>EU</b>: Europe</p> </li> <li> <p> <b>OC</b>: Oceania</p> </li> <li> <p> <b>NA</b>: North America</p> </li> <li> <p> <b>SA</b>: South America</p> </li> </ul>
  ##   countrycode: string
  ##              : Amazon Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.
  ##   subdivisioncode: string
  ##                  : Amazon Route 53 uses the one- to three-letter subdivision codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>. Route 53 doesn't support subdivision codes for all countries. If you specify <code>subdivisioncode</code>, you must also specify <code>countrycode</code>. 
  var query_606781 = newJObject()
  add(query_606781, "continentcode", newJString(continentcode))
  add(query_606781, "countrycode", newJString(countrycode))
  add(query_606781, "subdivisioncode", newJString(subdivisioncode))
  result = call_606780.call(nil, query_606781, nil, nil, nil)

var getGeoLocation* = Call_GetGeoLocation_606766(name: "getGeoLocation",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocation", validator: validate_GetGeoLocation_606767,
    base: "/", url: url_GetGeoLocation_606768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckCount_606782 = ref object of OpenApiRestCall_605589
proc url_GetHealthCheckCount_606784(protocol: Scheme; host: string; base: string;
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

proc validate_GetHealthCheckCount_606783(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606785 = header.getOrDefault("X-Amz-Signature")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Signature", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Content-Sha256", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Date")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Date", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Credential")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Credential", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Security-Token")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Security-Token", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Algorithm")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Algorithm", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-SignedHeaders", valid_606791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606792: Call_GetHealthCheckCount_606782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of health checks that are associated with the current AWS account.
  ## 
  let valid = call_606792.validator(path, query, header, formData, body)
  let scheme = call_606792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606792.url(scheme.get, call_606792.host, call_606792.base,
                         call_606792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606792, url, valid)

proc call*(call_606793: Call_GetHealthCheckCount_606782): Recallable =
  ## getHealthCheckCount
  ## Retrieves the number of health checks that are associated with the current AWS account.
  result = call_606793.call(nil, nil, nil, nil, nil)

var getHealthCheckCount* = Call_GetHealthCheckCount_606782(
    name: "getHealthCheckCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/healthcheckcount",
    validator: validate_GetHealthCheckCount_606783, base: "/",
    url: url_GetHealthCheckCount_606784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckLastFailureReason_606794 = ref object of OpenApiRestCall_605589
proc url_GetHealthCheckLastFailureReason_606796(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheckLastFailureReason_606795(path: JsonNode;
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
  var valid_606797 = path.getOrDefault("HealthCheckId")
  valid_606797 = validateParameter(valid_606797, JString, required = true,
                                 default = nil)
  if valid_606797 != nil:
    section.add "HealthCheckId", valid_606797
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
  var valid_606798 = header.getOrDefault("X-Amz-Signature")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Signature", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Content-Sha256", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Date")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Date", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Credential")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Credential", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Security-Token")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Security-Token", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Algorithm")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Algorithm", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-SignedHeaders", valid_606804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606805: Call_GetHealthCheckLastFailureReason_606794;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the reason that a specified health check failed most recently.
  ## 
  let valid = call_606805.validator(path, query, header, formData, body)
  let scheme = call_606805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606805.url(scheme.get, call_606805.host, call_606805.base,
                         call_606805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606805, url, valid)

proc call*(call_606806: Call_GetHealthCheckLastFailureReason_606794;
          HealthCheckId: string): Recallable =
  ## getHealthCheckLastFailureReason
  ## Gets the reason that a specified health check failed most recently.
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check for which you want the last failure reason. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to get the last failure reason for a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckLastFailureReason</code> for a calculated health check.</p> </note>
  var path_606807 = newJObject()
  add(path_606807, "HealthCheckId", newJString(HealthCheckId))
  result = call_606806.call(path_606807, nil, nil, nil, nil)

var getHealthCheckLastFailureReason* = Call_GetHealthCheckLastFailureReason_606794(
    name: "getHealthCheckLastFailureReason", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/lastfailurereason",
    validator: validate_GetHealthCheckLastFailureReason_606795, base: "/",
    url: url_GetHealthCheckLastFailureReason_606796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHealthCheckStatus_606808 = ref object of OpenApiRestCall_605589
proc url_GetHealthCheckStatus_606810(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHealthCheckStatus_606809(path: JsonNode; query: JsonNode;
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
  var valid_606811 = path.getOrDefault("HealthCheckId")
  valid_606811 = validateParameter(valid_606811, JString, required = true,
                                 default = nil)
  if valid_606811 != nil:
    section.add "HealthCheckId", valid_606811
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
  var valid_606812 = header.getOrDefault("X-Amz-Signature")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Signature", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Content-Sha256", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Date")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Date", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Credential")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Credential", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Security-Token")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Security-Token", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Algorithm")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Algorithm", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-SignedHeaders", valid_606818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606819: Call_GetHealthCheckStatus_606808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets status of a specified health check. 
  ## 
  let valid = call_606819.validator(path, query, header, formData, body)
  let scheme = call_606819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606819.url(scheme.get, call_606819.host, call_606819.base,
                         call_606819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606819, url, valid)

proc call*(call_606820: Call_GetHealthCheckStatus_606808; HealthCheckId: string): Recallable =
  ## getHealthCheckStatus
  ## Gets status of a specified health check. 
  ##   HealthCheckId: string (required)
  ##                : <p>The ID for the health check that you want the current status for. When you created the health check, <code>CreateHealthCheck</code> returned the ID in the response, in the <code>HealthCheckId</code> element.</p> <note> <p>If you want to check the status of a calculated health check, you must use the Amazon Route 53 console or the CloudWatch console. You can't use <code>GetHealthCheckStatus</code> to get the status of a calculated health check.</p> </note>
  var path_606821 = newJObject()
  add(path_606821, "HealthCheckId", newJString(HealthCheckId))
  result = call_606820.call(path_606821, nil, nil, nil, nil)

var getHealthCheckStatus* = Call_GetHealthCheckStatus_606808(
    name: "getHealthCheckStatus", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/healthcheck/{HealthCheckId}/status",
    validator: validate_GetHealthCheckStatus_606809, base: "/",
    url: url_GetHealthCheckStatus_606810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneCount_606822 = ref object of OpenApiRestCall_605589
proc url_GetHostedZoneCount_606824(protocol: Scheme; host: string; base: string;
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

proc validate_GetHostedZoneCount_606823(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606825 = header.getOrDefault("X-Amz-Signature")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Signature", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Content-Sha256", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Date")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Date", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Credential")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Credential", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Security-Token")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Security-Token", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Algorithm")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Algorithm", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-SignedHeaders", valid_606831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606832: Call_GetHostedZoneCount_606822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  ## 
  let valid = call_606832.validator(path, query, header, formData, body)
  let scheme = call_606832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606832.url(scheme.get, call_606832.host, call_606832.base,
                         call_606832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606832, url, valid)

proc call*(call_606833: Call_GetHostedZoneCount_606822): Recallable =
  ## getHostedZoneCount
  ## Retrieves the number of hosted zones that are associated with the current AWS account.
  result = call_606833.call(nil, nil, nil, nil, nil)

var getHostedZoneCount* = Call_GetHostedZoneCount_606822(
    name: "getHostedZoneCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonecount",
    validator: validate_GetHostedZoneCount_606823, base: "/",
    url: url_GetHostedZoneCount_606824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetHostedZoneLimit_606834 = ref object of OpenApiRestCall_605589
proc url_GetHostedZoneLimit_606836(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetHostedZoneLimit_606835(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  ##   Id: JString (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Type` field"
  var valid_606837 = path.getOrDefault("Type")
  valid_606837 = validateParameter(valid_606837, JString, required = true,
                                 default = newJString("MAX_RRSETS_BY_ZONE"))
  if valid_606837 != nil:
    section.add "Type", valid_606837
  var valid_606838 = path.getOrDefault("Id")
  valid_606838 = validateParameter(valid_606838, JString, required = true,
                                 default = nil)
  if valid_606838 != nil:
    section.add "Id", valid_606838
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
  var valid_606839 = header.getOrDefault("X-Amz-Signature")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Signature", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Content-Sha256", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Date")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Date", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Credential")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Credential", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Security-Token")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Security-Token", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Algorithm")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Algorithm", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-SignedHeaders", valid_606845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606846: Call_GetHostedZoneLimit_606834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_606846.validator(path, query, header, formData, body)
  let scheme = call_606846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606846.url(scheme.get, call_606846.host, call_606846.base,
                         call_606846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606846, url, valid)

proc call*(call_606847: Call_GetHostedZoneLimit_606834; Id: string;
          Type: string = "MAX_RRSETS_BY_ZONE"): Recallable =
  ## getHostedZoneLimit
  ## <p>Gets the specified limit for a specified hosted zone, for example, the maximum number of records that you can create in the hosted zone. </p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Type: string (required)
  ##       : <p>The limit that you want to get. Valid values include the following:</p> <ul> <li> <p> <b>MAX_RRSETS_BY_ZONE</b>: The maximum number of records that you can create in the specified hosted zone.</p> </li> <li> <p> <b>MAX_VPCS_ASSOCIATED_BY_ZONE</b>: The maximum number of Amazon VPCs that you can associate with the specified private hosted zone.</p> </li> </ul>
  ##   Id: string (required)
  ##     : The ID of the hosted zone that you want to get a limit for.
  var path_606848 = newJObject()
  add(path_606848, "Type", newJString(Type))
  add(path_606848, "Id", newJString(Id))
  result = call_606847.call(path_606848, nil, nil, nil, nil)

var getHostedZoneLimit* = Call_GetHostedZoneLimit_606834(
    name: "getHostedZoneLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/hostedzonelimit/{Id}/{Type}",
    validator: validate_GetHostedZoneLimit_606835, base: "/",
    url: url_GetHostedZoneLimit_606836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetReusableDelegationSetLimit_606849 = ref object of OpenApiRestCall_605589
proc url_GetReusableDelegationSetLimit_606851(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetReusableDelegationSetLimit_606850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Type: JString (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  ##   Id: JString (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Type` field"
  var valid_606852 = path.getOrDefault("Type")
  valid_606852 = validateParameter(valid_606852, JString, required = true, default = newJString(
      "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"))
  if valid_606852 != nil:
    section.add "Type", valid_606852
  var valid_606853 = path.getOrDefault("Id")
  valid_606853 = validateParameter(valid_606853, JString, required = true,
                                 default = nil)
  if valid_606853 != nil:
    section.add "Id", valid_606853
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
  var valid_606854 = header.getOrDefault("X-Amz-Signature")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Signature", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Content-Sha256", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Date")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Date", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Credential")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Credential", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Security-Token")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Security-Token", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Algorithm")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Algorithm", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-SignedHeaders", valid_606860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606861: Call_GetReusableDelegationSetLimit_606849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ## 
  let valid = call_606861.validator(path, query, header, formData, body)
  let scheme = call_606861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606861.url(scheme.get, call_606861.host, call_606861.base,
                         call_606861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606861, url, valid)

proc call*(call_606862: Call_GetReusableDelegationSetLimit_606849; Id: string;
          Type: string = "MAX_ZONES_BY_REUSABLE_DELEGATION_SET"): Recallable =
  ## getReusableDelegationSetLimit
  ## <p>Gets the maximum number of hosted zones that you can associate with the specified reusable delegation set.</p> <p>For the default limit, see <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSLimitations.html">Limits</a> in the <i>Amazon Route 53 Developer Guide</i>. To request a higher limit, <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-route53">open a case</a>.</p>
  ##   Type: string (required)
  ##       : Specify <code>MAX_ZONES_BY_REUSABLE_DELEGATION_SET</code> to get the maximum number of hosted zones that you can associate with the specified reusable delegation set.
  ##   Id: string (required)
  ##     : The ID of the delegation set that you want to get the limit for.
  var path_606863 = newJObject()
  add(path_606863, "Type", newJString(Type))
  add(path_606863, "Id", newJString(Id))
  result = call_606862.call(path_606863, nil, nil, nil, nil)

var getReusableDelegationSetLimit* = Call_GetReusableDelegationSetLimit_606849(
    name: "getReusableDelegationSetLimit", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/reusabledelegationsetlimit/{Id}/{Type}",
    validator: validate_GetReusableDelegationSetLimit_606850, base: "/",
    url: url_GetReusableDelegationSetLimit_606851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrafficPolicyInstanceCount_606864 = ref object of OpenApiRestCall_605589
proc url_GetTrafficPolicyInstanceCount_606866(protocol: Scheme; host: string;
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

proc validate_GetTrafficPolicyInstanceCount_606865(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606867 = header.getOrDefault("X-Amz-Signature")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Signature", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Content-Sha256", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Date")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Date", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Credential")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Credential", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Security-Token")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Security-Token", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Algorithm")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Algorithm", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-SignedHeaders", valid_606873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606874: Call_GetTrafficPolicyInstanceCount_606864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  ## 
  let valid = call_606874.validator(path, query, header, formData, body)
  let scheme = call_606874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606874.url(scheme.get, call_606874.host, call_606874.base,
                         call_606874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606874, url, valid)

proc call*(call_606875: Call_GetTrafficPolicyInstanceCount_606864): Recallable =
  ## getTrafficPolicyInstanceCount
  ## Gets the number of traffic policy instances that are associated with the current AWS account.
  result = call_606875.call(nil, nil, nil, nil, nil)

var getTrafficPolicyInstanceCount* = Call_GetTrafficPolicyInstanceCount_606864(
    name: "getTrafficPolicyInstanceCount", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstancecount",
    validator: validate_GetTrafficPolicyInstanceCount_606865, base: "/",
    url: url_GetTrafficPolicyInstanceCount_606866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGeoLocations_606876 = ref object of OpenApiRestCall_605589
proc url_ListGeoLocations_606878(protocol: Scheme; host: string; base: string;
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

proc validate_ListGeoLocations_606877(path: JsonNode; query: JsonNode;
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
  ##   startcontinentcode: JString
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  section = newJObject()
  var valid_606879 = query.getOrDefault("startcountrycode")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "startcountrycode", valid_606879
  var valid_606880 = query.getOrDefault("startsubdivisioncode")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "startsubdivisioncode", valid_606880
  var valid_606881 = query.getOrDefault("startcontinentcode")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "startcontinentcode", valid_606881
  var valid_606882 = query.getOrDefault("maxitems")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "maxitems", valid_606882
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
  if body != nil:
    result.add "body", body

proc call*(call_606890: Call_ListGeoLocations_606876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ## 
  let valid = call_606890.validator(path, query, header, formData, body)
  let scheme = call_606890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606890.url(scheme.get, call_606890.host, call_606890.base,
                         call_606890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606890, url, valid)

proc call*(call_606891: Call_ListGeoLocations_606876;
          startcountrycode: string = ""; startsubdivisioncode: string = "";
          startcontinentcode: string = ""; maxitems: string = ""): Recallable =
  ## listGeoLocations
  ## <p>Retrieves a list of supported geographic locations.</p> <p>Countries are listed first, and continents are listed last. If Amazon Route 53 supports subdivisions for a country (for example, states or provinces), the subdivisions for that country are listed in alphabetical order immediately after the corresponding country.</p>
  ##   startcountrycode: string
  ##                   : <p>The code for the country with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextCountryCode</code> from the previous response has a value, enter that value in <code>startcountrycode</code> to return the next page of results.</p> <p>Route 53 uses the two-letter country codes that are specified in <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO standard 3166-1 alpha-2</a>.</p>
  ##   startsubdivisioncode: string
  ##                       : <p>The code for the subdivision (for example, state or province) with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is <code>true</code>, and if <code>NextSubdivisionCode</code> from the previous response has a value, enter that value in <code>startsubdivisioncode</code> to return the next page of results.</p> <p>To list subdivisions of a country, you must include both <code>startcountrycode</code> and <code>startsubdivisioncode</code>.</p>
  ##   startcontinentcode: string
  ##                     : <p>The code for the continent with which you want to start listing locations that Amazon Route 53 supports for geolocation. If Route 53 has already returned a page or more of results, if <code>IsTruncated</code> is true, and if <code>NextContinentCode</code> from the previous response has a value, enter that value in <code>startcontinentcode</code> to return the next page of results.</p> <p>Include <code>startcontinentcode</code> only if you want to list continents. Don't include <code>startcontinentcode</code> when you're listing countries or countries with their subdivisions.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of geolocations to be included in the response body for this request. If more than <code>maxitems</code> geolocations remain to be listed, then the value of the <code>IsTruncated</code> element in the response is <code>true</code>.
  var query_606892 = newJObject()
  add(query_606892, "startcountrycode", newJString(startcountrycode))
  add(query_606892, "startsubdivisioncode", newJString(startsubdivisioncode))
  add(query_606892, "startcontinentcode", newJString(startcontinentcode))
  add(query_606892, "maxitems", newJString(maxitems))
  result = call_606891.call(nil, query_606892, nil, nil, nil)

var listGeoLocations* = Call_ListGeoLocations_606876(name: "listGeoLocations",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/geolocations", validator: validate_ListGeoLocations_606877,
    base: "/", url: url_ListGeoLocations_606878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHostedZonesByName_606893 = ref object of OpenApiRestCall_605589
proc url_ListHostedZonesByName_606895(protocol: Scheme; host: string; base: string;
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

proc validate_ListHostedZonesByName_606894(path: JsonNode; query: JsonNode;
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
  var valid_606896 = query.getOrDefault("dnsname")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "dnsname", valid_606896
  var valid_606897 = query.getOrDefault("maxitems")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "maxitems", valid_606897
  var valid_606898 = query.getOrDefault("hostedzoneid")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "hostedzoneid", valid_606898
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
  var valid_606899 = header.getOrDefault("X-Amz-Signature")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Signature", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Content-Sha256", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Date")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Date", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Credential")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Credential", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-Security-Token")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Security-Token", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Algorithm")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Algorithm", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-SignedHeaders", valid_606905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606906: Call_ListHostedZonesByName_606893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ## 
  let valid = call_606906.validator(path, query, header, formData, body)
  let scheme = call_606906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606906.url(scheme.get, call_606906.host, call_606906.base,
                         call_606906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606906, url, valid)

proc call*(call_606907: Call_ListHostedZonesByName_606893; dnsname: string = "";
          maxitems: string = ""; hostedzoneid: string = ""): Recallable =
  ## listHostedZonesByName
  ## <p>Retrieves a list of your hosted zones in lexicographic order. The response includes a <code>HostedZones</code> child element for each hosted zone created by the current AWS account. </p> <p> <code>ListHostedZonesByName</code> sorts hosted zones by name with the labels reversed. For example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order in some circumstances.</p> <p>If the domain name includes escape characters or Punycode, <code>ListHostedZonesByName</code> alphabetizes the domain name using the escaped or Punycoded value, which is the format that Amazon Route 53 saves in its database. For example, to create a hosted zone for exämple.com, you specify ex\344mple.com for the domain name. <code>ListHostedZonesByName</code> alphabetizes it as:</p> <p> <code>com.ex\344mple.</code> </p> <p>The labels are reversed and alphabetized using the escaped value. For more information about valid domain name formats, including internationalized domain names, see <a href="http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DomainNameFormat.html">DNS Domain Name Format</a> in the <i>Amazon Route 53 Developer Guide</i>.</p> <p>Route 53 returns up to 100 items in each response. If you have a lot of hosted zones, use the <code>MaxItems</code> parameter to list them in groups of up to 100. The response includes values that help navigate from one group of <code>MaxItems</code> hosted zones to the next:</p> <ul> <li> <p>The <code>DNSName</code> and <code>HostedZoneId</code> elements in the response contain the values, if any, specified for the <code>dnsname</code> and <code>hostedzoneid</code> parameters in the request that produced the current response.</p> </li> <li> <p>The <code>MaxItems</code> element in the response contains the value, if any, that you specified for the <code>maxitems</code> parameter in the request that produced the current response.</p> </li> <li> <p>If the value of <code>IsTruncated</code> in the response is true, there are more hosted zones associated with the current AWS account. </p> <p>If <code>IsTruncated</code> is false, this response includes the last hosted zone that is associated with the current account. The <code>NextDNSName</code> element and <code>NextHostedZoneId</code> elements are omitted from the response.</p> </li> <li> <p>The <code>NextDNSName</code> and <code>NextHostedZoneId</code> elements in the response contain the domain name and the hosted zone ID of the next hosted zone that is associated with the current AWS account. If you want to list more hosted zones, make another call to <code>ListHostedZonesByName</code>, and specify the value of <code>NextDNSName</code> and <code>NextHostedZoneId</code> in the <code>dnsname</code> and <code>hostedzoneid</code> parameters, respectively.</p> </li> </ul>
  ##   dnsname: string
  ##          : (Optional) For your first request to <code>ListHostedZonesByName</code>, include the <code>dnsname</code> parameter only if you want to specify the name of the first hosted zone in the response. If you don't include the <code>dnsname</code> parameter, Amazon Route 53 returns all of the hosted zones that were created by the current AWS account, in ASCII order. For subsequent requests, include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For <code>dnsname</code>, specify the value of <code>NextDNSName</code> from the previous response.
  ##   maxitems: string
  ##           : The maximum number of hosted zones to be included in the response body for this request. If you have more than <code>maxitems</code> hosted zones, then the value of the <code>IsTruncated</code> element in the response is true, and the values of <code>NextDNSName</code> and <code>NextHostedZoneId</code> specify the first hosted zone in the next group of <code>maxitems</code> hosted zones. 
  ##   hostedzoneid: string
  ##               : <p>(Optional) For your first request to <code>ListHostedZonesByName</code>, do not include the <code>hostedzoneid</code> parameter.</p> <p>If you have more hosted zones than the value of <code>maxitems</code>, <code>ListHostedZonesByName</code> returns only the first <code>maxitems</code> hosted zones. To get the next group of <code>maxitems</code> hosted zones, submit another request to <code>ListHostedZonesByName</code> and include both <code>dnsname</code> and <code>hostedzoneid</code> parameters. For the value of <code>hostedzoneid</code>, specify the value of the <code>NextHostedZoneId</code> element from the previous response.</p>
  var query_606908 = newJObject()
  add(query_606908, "dnsname", newJString(dnsname))
  add(query_606908, "maxitems", newJString(maxitems))
  add(query_606908, "hostedzoneid", newJString(hostedzoneid))
  result = call_606907.call(nil, query_606908, nil, nil, nil)

var listHostedZonesByName* = Call_ListHostedZonesByName_606893(
    name: "listHostedZonesByName", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzonesbyname",
    validator: validate_ListHostedZonesByName_606894, base: "/",
    url: url_ListHostedZonesByName_606895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceRecordSets_606909 = ref object of OpenApiRestCall_605589
proc url_ListResourceRecordSets_606911(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListResourceRecordSets_606910(path: JsonNode; query: JsonNode;
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
  var valid_606912 = path.getOrDefault("Id")
  valid_606912 = validateParameter(valid_606912, JString, required = true,
                                 default = nil)
  if valid_606912 != nil:
    section.add "Id", valid_606912
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: JString
  ##           : Pagination limit
  ##   type: JString
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   maxitems: JString
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: JString
  ##                  : Pagination token
  ##   StartRecordIdentifier: JString
  ##                        : Pagination token
  ##   StartRecordType: JString
  ##                  : Pagination token
  ##   identifier: JString
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  section = newJObject()
  var valid_606913 = query.getOrDefault("name")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "name", valid_606913
  var valid_606914 = query.getOrDefault("MaxItems")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "MaxItems", valid_606914
  var valid_606915 = query.getOrDefault("type")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = newJString("SOA"))
  if valid_606915 != nil:
    section.add "type", valid_606915
  var valid_606916 = query.getOrDefault("maxitems")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "maxitems", valid_606916
  var valid_606917 = query.getOrDefault("StartRecordName")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "StartRecordName", valid_606917
  var valid_606918 = query.getOrDefault("StartRecordIdentifier")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "StartRecordIdentifier", valid_606918
  var valid_606919 = query.getOrDefault("StartRecordType")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "StartRecordType", valid_606919
  var valid_606920 = query.getOrDefault("identifier")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "identifier", valid_606920
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
  var valid_606921 = header.getOrDefault("X-Amz-Signature")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Signature", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Content-Sha256", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Date")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Date", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Credential")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Credential", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Security-Token")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Security-Token", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Algorithm")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Algorithm", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-SignedHeaders", valid_606927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606928: Call_ListResourceRecordSets_606909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ## 
  let valid = call_606928.validator(path, query, header, formData, body)
  let scheme = call_606928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606928.url(scheme.get, call_606928.host, call_606928.base,
                         call_606928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606928, url, valid)

proc call*(call_606929: Call_ListResourceRecordSets_606909; Id: string;
          name: string = ""; MaxItems: string = ""; `type`: string = "SOA";
          maxitems: string = ""; StartRecordName: string = "";
          StartRecordIdentifier: string = ""; StartRecordType: string = "";
          identifier: string = ""): Recallable =
  ## listResourceRecordSets
  ## <p>Lists the resource record sets in a specified hosted zone.</p> <p> <code>ListResourceRecordSets</code> returns up to 100 resource record sets at a time in ASCII order, beginning at a position specified by the <code>name</code> and <code>type</code> elements.</p> <p> <b>Sort order</b> </p> <p> <code>ListResourceRecordSets</code> sorts results first by DNS name with the labels reversed, for example:</p> <p> <code>com.example.www.</code> </p> <p>Note the trailing dot, which can change the sort order when the record name contains characters that appear before <code>.</code> (decimal 46) in the ASCII table. These characters include the following: <code>! " # $ % &amp; ' ( ) * + , -</code> </p> <p>When multiple records have the same DNS name, <code>ListResourceRecordSets</code> sorts results by the record type.</p> <p> <b>Specifying where to start listing records</b> </p> <p>You can use the name and type elements to specify the resource record set that the list begins with:</p> <dl> <dt>If you do not specify Name or Type</dt> <dd> <p>The results begin with the first resource record set that the hosted zone contains.</p> </dd> <dt>If you specify Name but not Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>.</p> </dd> <dt>If you specify Type but not Name</dt> <dd> <p>Amazon Route 53 returns the <code>InvalidInput</code> error.</p> </dd> <dt>If you specify both Name and Type</dt> <dd> <p>The results begin with the first resource record set in the list whose name is greater than or equal to <code>Name</code>, and whose type is greater than or equal to <code>Type</code>.</p> </dd> </dl> <p> <b>Resource record sets that are PENDING</b> </p> <p>This action returns the most current version of the records. This includes records that are <code>PENDING</code>, and that are not yet available on all Route 53 DNS servers.</p> <p> <b>Changing resource record sets</b> </p> <p>To ensure that you get an accurate listing of the resource record sets for a hosted zone at a point in time, do not submit a <code>ChangeResourceRecordSets</code> request while you're paging through the results of a <code>ListResourceRecordSets</code> request. If you do, some pages may display results without the latest changes while other pages display results with the latest changes.</p> <p> <b>Displaying the next page of results</b> </p> <p>If a <code>ListResourceRecordSets</code> command returns more than one page of results, the value of <code>IsTruncated</code> is <code>true</code>. To display the next page of results, get the values of <code>NextRecordName</code>, <code>NextRecordType</code>, and <code>NextRecordIdentifier</code> (if any) from the response. Then submit another <code>ListResourceRecordSets</code> request, and specify those values for <code>StartRecordName</code>, <code>StartRecordType</code>, and <code>StartRecordIdentifier</code>.</p>
  ##   name: string
  ##       : The first name in the lexicographic ordering of resource record sets that you want to list.
  ##   MaxItems: string
  ##           : Pagination limit
  ##   type: string
  ##       : <p>The type of resource record set to begin the record listing from.</p> <p>Valid values for basic resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>NS</code> | <code>PTR</code> | <code>SOA</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for weighted, latency, geolocation, and failover resource record sets: <code>A</code> | <code>AAAA</code> | <code>CAA</code> | <code>CNAME</code> | <code>MX</code> | <code>NAPTR</code> | <code>PTR</code> | <code>SPF</code> | <code>SRV</code> | <code>TXT</code> </p> <p>Values for alias resource record sets: </p> <ul> <li> <p> <b>API Gateway custom regional API or edge-optimized API</b>: A</p> </li> <li> <p> <b>CloudFront distribution</b>: A or AAAA</p> </li> <li> <p> <b>Elastic Beanstalk environment that has a regionalized subdomain</b>: A</p> </li> <li> <p> <b>Elastic Load Balancing load balancer</b>: A | AAAA</p> </li> <li> <p> <b>Amazon S3 bucket</b>: A</p> </li> <li> <p> <b>Amazon VPC interface VPC endpoint</b>: A</p> </li> <li> <p> <b>Another resource record set in this hosted zone:</b> The type of the resource record set that the alias references.</p> </li> </ul> <p>Constraint: Specifying <code>type</code> without specifying <code>name</code> returns an <code>InvalidInput</code> error.</p>
  ##   maxitems: string
  ##           : (Optional) The maximum number of resource records sets to include in the response body for this request. If the response includes more than <code>maxitems</code> resource record sets, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of the <code>NextRecordName</code> and <code>NextRecordType</code> elements in the response identify the first resource record set in the next group of <code>maxitems</code> resource record sets.
  ##   StartRecordName: string
  ##                  : Pagination token
  ##   StartRecordIdentifier: string
  ##                        : Pagination token
  ##   StartRecordType: string
  ##                  : Pagination token
  ##   Id: string (required)
  ##     : The ID of the hosted zone that contains the resource record sets that you want to list.
  ##   identifier: string
  ##             :  <i>Resource record sets that have a routing policy other than simple:</i> If results were truncated for a given DNS name and type, specify the value of <code>NextRecordIdentifier</code> from the previous response to get the next resource record set that has the current DNS name and type.
  var path_606930 = newJObject()
  var query_606931 = newJObject()
  add(query_606931, "name", newJString(name))
  add(query_606931, "MaxItems", newJString(MaxItems))
  add(query_606931, "type", newJString(`type`))
  add(query_606931, "maxitems", newJString(maxitems))
  add(query_606931, "StartRecordName", newJString(StartRecordName))
  add(query_606931, "StartRecordIdentifier", newJString(StartRecordIdentifier))
  add(query_606931, "StartRecordType", newJString(StartRecordType))
  add(path_606930, "Id", newJString(Id))
  add(query_606931, "identifier", newJString(identifier))
  result = call_606929.call(path_606930, query_606931, nil, nil, nil)

var listResourceRecordSets* = Call_ListResourceRecordSets_606909(
    name: "listResourceRecordSets", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/hostedzone/{Id}/rrset",
    validator: validate_ListResourceRecordSets_606910, base: "/",
    url: url_ListResourceRecordSets_606911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResources_606932 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResources_606934(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResources_606933(path: JsonNode; query: JsonNode;
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
  var valid_606935 = path.getOrDefault("ResourceType")
  valid_606935 = validateParameter(valid_606935, JString, required = true,
                                 default = newJString("healthcheck"))
  if valid_606935 != nil:
    section.add "ResourceType", valid_606935
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
  var valid_606936 = header.getOrDefault("X-Amz-Signature")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Signature", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Content-Sha256", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Date")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Date", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Credential")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Credential", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Security-Token")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Security-Token", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Algorithm")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Algorithm", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-SignedHeaders", valid_606942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606944: Call_ListTagsForResources_606932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ## 
  let valid = call_606944.validator(path, query, header, formData, body)
  let scheme = call_606944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606944.url(scheme.get, call_606944.host, call_606944.base,
                         call_606944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606944, url, valid)

proc call*(call_606945: Call_ListTagsForResources_606932; body: JsonNode;
          ResourceType: string = "healthcheck"): Recallable =
  ## listTagsForResources
  ## <p>Lists tags for up to 10 health checks or hosted zones.</p> <p>For information about using tags for cost allocation, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html">Using Cost Allocation Tags</a> in the <i>AWS Billing and Cost Management User Guide</i>.</p>
  ##   ResourceType: string (required)
  ##               : <p>The type of the resources.</p> <ul> <li> <p>The resource type for health checks is <code>healthcheck</code>.</p> </li> <li> <p>The resource type for hosted zones is <code>hostedzone</code>.</p> </li> </ul>
  ##   body: JObject (required)
  var path_606946 = newJObject()
  var body_606947 = newJObject()
  add(path_606946, "ResourceType", newJString(ResourceType))
  if body != nil:
    body_606947 = body
  result = call_606945.call(path_606946, nil, nil, nil, body_606947)

var listTagsForResources* = Call_ListTagsForResources_606932(
    name: "listTagsForResources", meth: HttpMethod.HttpPost,
    host: "route53.amazonaws.com", route: "/2013-04-01/tags/{ResourceType}",
    validator: validate_ListTagsForResources_606933, base: "/",
    url: url_ListTagsForResources_606934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicies_606948 = ref object of OpenApiRestCall_605589
proc url_ListTrafficPolicies_606950(protocol: Scheme; host: string; base: string;
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

proc validate_ListTrafficPolicies_606949(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  ##   trafficpolicyid: JString
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  section = newJObject()
  var valid_606951 = query.getOrDefault("maxitems")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "maxitems", valid_606951
  var valid_606952 = query.getOrDefault("trafficpolicyid")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "trafficpolicyid", valid_606952
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
  var valid_606953 = header.getOrDefault("X-Amz-Signature")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Signature", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Content-Sha256", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Date")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Date", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Credential")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Credential", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Security-Token")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Security-Token", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Algorithm")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Algorithm", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-SignedHeaders", valid_606959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606960: Call_ListTrafficPolicies_606948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ## 
  let valid = call_606960.validator(path, query, header, formData, body)
  let scheme = call_606960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606960.url(scheme.get, call_606960.host, call_606960.base,
                         call_606960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606960, url, valid)

proc call*(call_606961: Call_ListTrafficPolicies_606948; maxitems: string = "";
          trafficpolicyid: string = ""): Recallable =
  ## listTrafficPolicies
  ## Gets information about the latest version for every traffic policy that is associated with the current AWS account. Policies are listed in the order that they were created in. 
  ##   maxitems: string
  ##           : (Optional) The maximum number of traffic policies that you want Amazon Route 53 to return in response to this request. If you have more than <code>MaxItems</code> traffic policies, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of <code>TrafficPolicyIdMarker</code> is the ID of the first traffic policy that Route 53 will return if you submit another request.
  ##   trafficpolicyid: string
  ##                  : <p>(Conditional) For your first request to <code>ListTrafficPolicies</code>, don't include the <code>TrafficPolicyIdMarker</code> parameter.</p> <p>If you have more traffic policies than the value of <code>MaxItems</code>, <code>ListTrafficPolicies</code> returns only the first <code>MaxItems</code> traffic policies. To get the next group of policies, submit another request to <code>ListTrafficPolicies</code>. For the value of <code>TrafficPolicyIdMarker</code>, specify the value of <code>TrafficPolicyIdMarker</code> that was returned in the previous response.</p>
  var query_606962 = newJObject()
  add(query_606962, "maxitems", newJString(maxitems))
  add(query_606962, "trafficpolicyid", newJString(trafficpolicyid))
  result = call_606961.call(nil, query_606962, nil, nil, nil)

var listTrafficPolicies* = Call_ListTrafficPolicies_606948(
    name: "listTrafficPolicies", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicies",
    validator: validate_ListTrafficPolicies_606949, base: "/",
    url: url_ListTrafficPolicies_606950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstances_606963 = ref object of OpenApiRestCall_605589
proc url_ListTrafficPolicyInstances_606965(protocol: Scheme; host: string;
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

proc validate_ListTrafficPolicyInstances_606964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_606966 = query.getOrDefault("trafficpolicyinstancetype")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = newJString("SOA"))
  if valid_606966 != nil:
    section.add "trafficpolicyinstancetype", valid_606966
  var valid_606967 = query.getOrDefault("maxitems")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "maxitems", valid_606967
  var valid_606968 = query.getOrDefault("trafficpolicyinstancename")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "trafficpolicyinstancename", valid_606968
  var valid_606969 = query.getOrDefault("hostedzoneid")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "hostedzoneid", valid_606969
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
  var valid_606970 = header.getOrDefault("X-Amz-Signature")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Signature", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-Content-Sha256", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Date")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Date", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Credential")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Credential", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Security-Token")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Security-Token", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-Algorithm")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Algorithm", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-SignedHeaders", valid_606976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606977: Call_ListTrafficPolicyInstances_606963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_606977.validator(path, query, header, formData, body)
  let scheme = call_606977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606977.url(scheme.get, call_606977.host, call_606977.base,
                         call_606977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606977, url, valid)

proc call*(call_606978: Call_ListTrafficPolicyInstances_606963;
          trafficpolicyinstancetype: string = "SOA"; maxitems: string = "";
          trafficpolicyinstancename: string = ""; hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstances
  ## <p>Gets information about the traffic policy instances that you created by using the current AWS account.</p> <note> <p>After you submit an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances that you want Amazon Route 53 to return in response to a <code>ListTrafficPolicyInstances</code> request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance in the next group of <code>MaxItems</code> traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>HostedZoneId</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_606979 = newJObject()
  add(query_606979, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_606979, "maxitems", newJString(maxitems))
  add(query_606979, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_606979, "hostedzoneid", newJString(hostedzoneid))
  result = call_606978.call(nil, query_606979, nil, nil, nil)

var listTrafficPolicyInstances* = Call_ListTrafficPolicyInstances_606963(
    name: "listTrafficPolicyInstances", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com", route: "/2013-04-01/trafficpolicyinstances",
    validator: validate_ListTrafficPolicyInstances_606964, base: "/",
    url: url_ListTrafficPolicyInstances_606965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByHostedZone_606980 = ref object of OpenApiRestCall_605589
proc url_ListTrafficPolicyInstancesByHostedZone_606982(protocol: Scheme;
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

proc validate_ListTrafficPolicyInstancesByHostedZone_606981(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: JString (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_606983 = query.getOrDefault("trafficpolicyinstancetype")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = newJString("SOA"))
  if valid_606983 != nil:
    section.add "trafficpolicyinstancetype", valid_606983
  var valid_606984 = query.getOrDefault("maxitems")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "maxitems", valid_606984
  assert query != nil, "query argument is necessary due to required `id` field"
  var valid_606985 = query.getOrDefault("id")
  valid_606985 = validateParameter(valid_606985, JString, required = true,
                                 default = nil)
  if valid_606985 != nil:
    section.add "id", valid_606985
  var valid_606986 = query.getOrDefault("trafficpolicyinstancename")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "trafficpolicyinstancename", valid_606986
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
  var valid_606987 = header.getOrDefault("X-Amz-Signature")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Signature", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Content-Sha256", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-Date")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-Date", valid_606989
  var valid_606990 = header.getOrDefault("X-Amz-Credential")
  valid_606990 = validateParameter(valid_606990, JString, required = false,
                                 default = nil)
  if valid_606990 != nil:
    section.add "X-Amz-Credential", valid_606990
  var valid_606991 = header.getOrDefault("X-Amz-Security-Token")
  valid_606991 = validateParameter(valid_606991, JString, required = false,
                                 default = nil)
  if valid_606991 != nil:
    section.add "X-Amz-Security-Token", valid_606991
  var valid_606992 = header.getOrDefault("X-Amz-Algorithm")
  valid_606992 = validateParameter(valid_606992, JString, required = false,
                                 default = nil)
  if valid_606992 != nil:
    section.add "X-Amz-Algorithm", valid_606992
  var valid_606993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606993 = validateParameter(valid_606993, JString, required = false,
                                 default = nil)
  if valid_606993 != nil:
    section.add "X-Amz-SignedHeaders", valid_606993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606994: Call_ListTrafficPolicyInstancesByHostedZone_606980;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_606994.validator(path, query, header, formData, body)
  let scheme = call_606994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606994.url(scheme.get, call_606994.host, call_606994.base,
                         call_606994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606994, url, valid)

proc call*(call_606995: Call_ListTrafficPolicyInstancesByHostedZone_606980;
          id: string; trafficpolicyinstancetype: string = "SOA";
          maxitems: string = ""; trafficpolicyinstancename: string = ""): Recallable =
  ## listTrafficPolicyInstancesByHostedZone
  ## <p>Gets information about the traffic policy instances that you created in a specified hosted zone.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the type of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: string (required)
  ##     : The ID of the hosted zone that you want to list traffic policy instances for.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response is true, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstances</code> request. For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance in the next group of traffic policy instances.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_606996 = newJObject()
  add(query_606996, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_606996, "maxitems", newJString(maxitems))
  add(query_606996, "id", newJString(id))
  add(query_606996, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  result = call_606995.call(nil, query_606996, nil, nil, nil)

var listTrafficPolicyInstancesByHostedZone* = Call_ListTrafficPolicyInstancesByHostedZone_606980(
    name: "listTrafficPolicyInstancesByHostedZone", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/hostedzone#id",
    validator: validate_ListTrafficPolicyInstancesByHostedZone_606981, base: "/",
    url: url_ListTrafficPolicyInstancesByHostedZone_606982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyInstancesByPolicy_606997 = ref object of OpenApiRestCall_605589
proc url_ListTrafficPolicyInstancesByPolicy_606999(protocol: Scheme; host: string;
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

proc validate_ListTrafficPolicyInstancesByPolicy_606998(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   trafficpolicyinstancetype: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: JInt (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   maxitems: JString
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: JString (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: JString
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: JString
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  section = newJObject()
  var valid_607000 = query.getOrDefault("trafficpolicyinstancetype")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = newJString("SOA"))
  if valid_607000 != nil:
    section.add "trafficpolicyinstancetype", valid_607000
  assert query != nil, "query argument is necessary due to required `version` field"
  var valid_607001 = query.getOrDefault("version")
  valid_607001 = validateParameter(valid_607001, JInt, required = true, default = nil)
  if valid_607001 != nil:
    section.add "version", valid_607001
  var valid_607002 = query.getOrDefault("maxitems")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "maxitems", valid_607002
  var valid_607003 = query.getOrDefault("id")
  valid_607003 = validateParameter(valid_607003, JString, required = true,
                                 default = nil)
  if valid_607003 != nil:
    section.add "id", valid_607003
  var valid_607004 = query.getOrDefault("trafficpolicyinstancename")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "trafficpolicyinstancename", valid_607004
  var valid_607005 = query.getOrDefault("hostedzoneid")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "hostedzoneid", valid_607005
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
  var valid_607006 = header.getOrDefault("X-Amz-Signature")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Signature", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Content-Sha256", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-Date")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-Date", valid_607008
  var valid_607009 = header.getOrDefault("X-Amz-Credential")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Credential", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Security-Token")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Security-Token", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Algorithm")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Algorithm", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-SignedHeaders", valid_607012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607013: Call_ListTrafficPolicyInstancesByPolicy_606997;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ## 
  let valid = call_607013.validator(path, query, header, formData, body)
  let scheme = call_607013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607013.url(scheme.get, call_607013.host, call_607013.base,
                         call_607013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607013, url, valid)

proc call*(call_607014: Call_ListTrafficPolicyInstancesByPolicy_606997;
          version: int; id: string; trafficpolicyinstancetype: string = "SOA";
          maxitems: string = ""; trafficpolicyinstancename: string = "";
          hostedzoneid: string = ""): Recallable =
  ## listTrafficPolicyInstancesByPolicy
  ## <p>Gets information about the traffic policy instances that you created by using a specify traffic policy version.</p> <note> <p>After you submit a <code>CreateTrafficPolicyInstance</code> or an <code>UpdateTrafficPolicyInstance</code> request, there's a brief delay while Amazon Route 53 creates the resource record sets that are specified in the traffic policy definition. For more information, see the <code>State</code> response element.</p> </note> <p>Route 53 returns a maximum of 100 items in each response. If you have a lot of traffic policy instances, you can use the <code>MaxItems</code> parameter to list them in groups of up to 100.</p>
  ##   trafficpolicyinstancetype: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancetype</code>, specify the value of <code>TrafficPolicyInstanceTypeMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   version: int (required)
  ##          : The version of the traffic policy for which you want to list traffic policy instances. The version must be associated with the traffic policy that is specified by <code>TrafficPolicyId</code>.
  ##   maxitems: string
  ##           : The maximum number of traffic policy instances to be included in the response body for this request. If you have more than <code>MaxItems</code> traffic policy instances, the value of the <code>IsTruncated</code> element in the response is <code>true</code>, and the values of <code>HostedZoneIdMarker</code>, <code>TrafficPolicyInstanceNameMarker</code>, and <code>TrafficPolicyInstanceTypeMarker</code> represent the first traffic policy instance that Amazon Route 53 will return if you submit another request.
  ##   id: string (required)
  ##     : The ID of the traffic policy for which you want to list traffic policy instances.
  ##   trafficpolicyinstancename: string
  ##                            : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request.</p> <p>For the value of <code>trafficpolicyinstancename</code>, specify the value of <code>TrafficPolicyInstanceNameMarker</code> from the previous response, which is the name of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  ##   hostedzoneid: string
  ##               : <p>If the value of <code>IsTruncated</code> in the previous response was <code>true</code>, you have more traffic policy instances. To get more traffic policy instances, submit another <code>ListTrafficPolicyInstancesByPolicy</code> request. </p> <p>For the value of <code>hostedzoneid</code>, specify the value of <code>HostedZoneIdMarker</code> from the previous response, which is the hosted zone ID of the first traffic policy instance that Amazon Route 53 will return if you submit another request.</p> <p>If the value of <code>IsTruncated</code> in the previous response was <code>false</code>, there are no more traffic policy instances to get.</p>
  var query_607015 = newJObject()
  add(query_607015, "trafficpolicyinstancetype",
      newJString(trafficpolicyinstancetype))
  add(query_607015, "version", newJInt(version))
  add(query_607015, "maxitems", newJString(maxitems))
  add(query_607015, "id", newJString(id))
  add(query_607015, "trafficpolicyinstancename",
      newJString(trafficpolicyinstancename))
  add(query_607015, "hostedzoneid", newJString(hostedzoneid))
  result = call_607014.call(nil, query_607015, nil, nil, nil)

var listTrafficPolicyInstancesByPolicy* = Call_ListTrafficPolicyInstancesByPolicy_606997(
    name: "listTrafficPolicyInstancesByPolicy", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicyinstances/trafficpolicy#id&version",
    validator: validate_ListTrafficPolicyInstancesByPolicy_606998, base: "/",
    url: url_ListTrafficPolicyInstancesByPolicy_606999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrafficPolicyVersions_607016 = ref object of OpenApiRestCall_605589
proc url_ListTrafficPolicyVersions_607018(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTrafficPolicyVersions_607017(path: JsonNode; query: JsonNode;
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
  var valid_607019 = path.getOrDefault("Id")
  valid_607019 = validateParameter(valid_607019, JString, required = true,
                                 default = nil)
  if valid_607019 != nil:
    section.add "Id", valid_607019
  result.add "path", section
  ## parameters in `query` object:
  ##   maxitems: JString
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  ##   trafficpolicyversion: JString
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  section = newJObject()
  var valid_607020 = query.getOrDefault("maxitems")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "maxitems", valid_607020
  var valid_607021 = query.getOrDefault("trafficpolicyversion")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "trafficpolicyversion", valid_607021
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
  var valid_607022 = header.getOrDefault("X-Amz-Signature")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Signature", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Content-Sha256", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Date")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Date", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Credential")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Credential", valid_607025
  var valid_607026 = header.getOrDefault("X-Amz-Security-Token")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "X-Amz-Security-Token", valid_607026
  var valid_607027 = header.getOrDefault("X-Amz-Algorithm")
  valid_607027 = validateParameter(valid_607027, JString, required = false,
                                 default = nil)
  if valid_607027 != nil:
    section.add "X-Amz-Algorithm", valid_607027
  var valid_607028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-SignedHeaders", valid_607028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607029: Call_ListTrafficPolicyVersions_607016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ## 
  let valid = call_607029.validator(path, query, header, formData, body)
  let scheme = call_607029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607029.url(scheme.get, call_607029.host, call_607029.base,
                         call_607029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607029, url, valid)

proc call*(call_607030: Call_ListTrafficPolicyVersions_607016; Id: string;
          maxitems: string = ""; trafficpolicyversion: string = ""): Recallable =
  ## listTrafficPolicyVersions
  ## <p>Gets information about all of the versions for a specified traffic policy.</p> <p>Traffic policy versions are listed in numerical order by <code>VersionNumber</code>.</p>
  ##   maxitems: string
  ##           : The maximum number of traffic policy versions that you want Amazon Route 53 to include in the response body for this request. If the specified traffic policy has more than <code>MaxItems</code> versions, the value of <code>IsTruncated</code> in the response is <code>true</code>, and the value of the <code>TrafficPolicyVersionMarker</code> element is the ID of the first version that Route 53 will return if you submit another request.
  ##   trafficpolicyversion: string
  ##                       : <p>For your first request to <code>ListTrafficPolicyVersions</code>, don't include the <code>TrafficPolicyVersionMarker</code> parameter.</p> <p>If you have more traffic policy versions than the value of <code>MaxItems</code>, <code>ListTrafficPolicyVersions</code> returns only the first group of <code>MaxItems</code> versions. To get more traffic policy versions, submit another <code>ListTrafficPolicyVersions</code> request. For the value of <code>TrafficPolicyVersionMarker</code>, specify the value of <code>TrafficPolicyVersionMarker</code> in the previous response.</p>
  ##   Id: string (required)
  ##     : Specify the value of <code>Id</code> of the traffic policy for which you want to list all versions.
  var path_607031 = newJObject()
  var query_607032 = newJObject()
  add(query_607032, "maxitems", newJString(maxitems))
  add(query_607032, "trafficpolicyversion", newJString(trafficpolicyversion))
  add(path_607031, "Id", newJString(Id))
  result = call_607030.call(path_607031, query_607032, nil, nil, nil)

var listTrafficPolicyVersions* = Call_ListTrafficPolicyVersions_607016(
    name: "listTrafficPolicyVersions", meth: HttpMethod.HttpGet,
    host: "route53.amazonaws.com",
    route: "/2013-04-01/trafficpolicies/{Id}/versions",
    validator: validate_ListTrafficPolicyVersions_607017, base: "/",
    url: url_ListTrafficPolicyVersions_607018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestDNSAnswer_607033 = ref object of OpenApiRestCall_605589
proc url_TestDNSAnswer_607035(protocol: Scheme; host: string; base: string;
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

proc validate_TestDNSAnswer_607034(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   edns0clientsubnetip: JString
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   edns0clientsubnetmask: JString
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   recordname: JString (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   resolverip: JString
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordtype: JString (required)
  ##             : The type of the resource record set.
  ##   hostedzoneid: JString (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  section = newJObject()
  var valid_607036 = query.getOrDefault("edns0clientsubnetip")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "edns0clientsubnetip", valid_607036
  var valid_607037 = query.getOrDefault("edns0clientsubnetmask")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "edns0clientsubnetmask", valid_607037
  assert query != nil,
        "query argument is necessary due to required `recordname` field"
  var valid_607038 = query.getOrDefault("recordname")
  valid_607038 = validateParameter(valid_607038, JString, required = true,
                                 default = nil)
  if valid_607038 != nil:
    section.add "recordname", valid_607038
  var valid_607039 = query.getOrDefault("resolverip")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "resolverip", valid_607039
  var valid_607040 = query.getOrDefault("recordtype")
  valid_607040 = validateParameter(valid_607040, JString, required = true,
                                 default = newJString("SOA"))
  if valid_607040 != nil:
    section.add "recordtype", valid_607040
  var valid_607041 = query.getOrDefault("hostedzoneid")
  valid_607041 = validateParameter(valid_607041, JString, required = true,
                                 default = nil)
  if valid_607041 != nil:
    section.add "hostedzoneid", valid_607041
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
  var valid_607042 = header.getOrDefault("X-Amz-Signature")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "X-Amz-Signature", valid_607042
  var valid_607043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Content-Sha256", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Date")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Date", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Credential")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Credential", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Security-Token")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Security-Token", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Algorithm")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Algorithm", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-SignedHeaders", valid_607048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607049: Call_TestDNSAnswer_607033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ## 
  let valid = call_607049.validator(path, query, header, formData, body)
  let scheme = call_607049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607049.url(scheme.get, call_607049.host, call_607049.base,
                         call_607049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607049, url, valid)

proc call*(call_607050: Call_TestDNSAnswer_607033; recordname: string;
          hostedzoneid: string; edns0clientsubnetip: string = "";
          edns0clientsubnetmask: string = ""; resolverip: string = "";
          recordtype: string = "SOA"): Recallable =
  ## testDNSAnswer
  ## Gets the value that Amazon Route 53 returns in response to a DNS request for a specified record name and type. You can optionally specify the IP address of a DNS resolver, an EDNS0 client subnet IP address, and a subnet mask. 
  ##   edns0clientsubnetip: string
  ##                      : If the resolver that you specified for resolverip supports EDNS0, specify the IPv4 or IPv6 address of a client in the applicable location, for example, <code>192.0.2.44</code> or <code>2001:db8:85a3::8a2e:370:7334</code>.
  ##   edns0clientsubnetmask: string
  ##                        : <p>If you specify an IP address for <code>edns0clientsubnetip</code>, you can optionally specify the number of bits of the IP address that you want the checking tool to include in the DNS query. For example, if you specify <code>192.0.2.44</code> for <code>edns0clientsubnetip</code> and <code>24</code> for <code>edns0clientsubnetmask</code>, the checking tool will simulate a request from 192.0.2.0/24. The default value is 24 bits for IPv4 addresses and 64 bits for IPv6 addresses.</p> <p>The range of valid values depends on whether <code>edns0clientsubnetip</code> is an IPv4 or an IPv6 address:</p> <ul> <li> <p> <b>IPv4</b>: Specify a value between 0 and 32</p> </li> <li> <p> <b>IPv6</b>: Specify a value between 0 and 128</p> </li> </ul>
  ##   recordname: string (required)
  ##             : The name of the resource record set that you want Amazon Route 53 to simulate a query for.
  ##   resolverip: string
  ##             : If you want to simulate a request from a specific DNS resolver, specify the IP address for that resolver. If you omit this value, <code>TestDnsAnswer</code> uses the IP address of a DNS resolver in the AWS US East (N. Virginia) Region (<code>us-east-1</code>).
  ##   recordtype: string (required)
  ##             : The type of the resource record set.
  ##   hostedzoneid: string (required)
  ##               : The ID of the hosted zone that you want Amazon Route 53 to simulate a query for.
  var query_607051 = newJObject()
  add(query_607051, "edns0clientsubnetip", newJString(edns0clientsubnetip))
  add(query_607051, "edns0clientsubnetmask", newJString(edns0clientsubnetmask))
  add(query_607051, "recordname", newJString(recordname))
  add(query_607051, "resolverip", newJString(resolverip))
  add(query_607051, "recordtype", newJString(recordtype))
  add(query_607051, "hostedzoneid", newJString(hostedzoneid))
  result = call_607050.call(nil, query_607051, nil, nil, nil)

var testDNSAnswer* = Call_TestDNSAnswer_607033(name: "testDNSAnswer",
    meth: HttpMethod.HttpGet, host: "route53.amazonaws.com",
    route: "/2013-04-01/testdnsanswer#hostedzoneid&recordname&recordtype",
    validator: validate_TestDNSAnswer_607034, base: "/", url: url_TestDNSAnswer_607035,
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
